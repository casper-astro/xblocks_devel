function twiddle_stage_2_init_xblock(a_re, a_im, b_re, b_im, sync, ...
    a_re_out, a_im_out, bw_re_out, bw_im_out, sync_out, ...
    FFTSize, input_bit_width, mux_latency, negate_latency, conv_latency, use_dsp48e)
%% diagram

	if use_dsp48e
		negate_latency = 3;
	end

	negate_out1 = xSignal;
	convert_out1 = xSignal;
	count = xSignal;
	sel = xSignal;
	im_sel = xSignal;
	delay3_out1 = xSignal;
	delay4_out1 = xSignal;
	b_re_bram_del = xSignal;
	b_im_bram_del = xSignal;
	counter_rst = xSignal;
	

	% delay output sync pulse by negate_latency to generate counter reset
	counter_rst_del = xBlock(struct('source', 'Delay', 'name', 'counter_rst_del'), ...
						   struct('latency', negate_latency, 'reg_retiming', 'on'), {sync}, {counter_rst});
	
	% delay counter_rst by mux_latency for output sync                       
	sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
						   struct('latency', mux_latency, 'reg_retiming', 'on'), {counter_rst}, {sync_out});
	
	% Counter for select signal 
	counter = xBlock(struct('source', 'Counter', 'name', 'counter'), ...
							struct('n_bits', FFTSize - 1 , 'rst', 'on', 'use_behavioral_HDL', 'on'), {counter_rst}, {count});
	% slice to extract mux select from counter 
	slice = xBlock(struct('source', 'Slice', 'name', 'slice'), [], {count}, {sel});
	
	
	% delay a_re by total delay 
	a_re_del = xBlock(struct('source', 'Delay', 'name', 'a_re_del'), ...
						   struct('latency', negate_latency+mux_latency, 'reg_retiming', 'on'), {a_re}, {a_re_out});
	
	% delay a_im by total delay
	a_im_del = xBlock(struct('source', 'Delay', 'name', 'a_im_del'), ...
						   struct('latency', negate_latency+mux_latency, 'reg_retiming', 'on'), {a_im}, {a_im_out});
	
	% delay 'select' for im select mux
	im_sel_del = xBlock(struct('source', 'Delay', 'name', 'im_sel_del'), ...
						   struct('latency', mux_latency-1, 'reg_retiming', 'on'), ...
						   {sel}, {im_sel});

	% delay b_re by bram_delay 
	b_re_bram_del_sub = xBlock(struct('source', 'Delay', 'name', 'b_re_bram_del'), ...
						   struct('latency', negate_latency, 'reg_retiming', 'on'), {b_re}, {b_re_bram_del});
	
	% delay b_im by bram_delay
	b_im_bram_del_sub = xBlock(struct('source', 'Delay', 'name', 'b_im_bram_del'), ...
						   struct('latency', negate_latency, 'reg_retiming', 'on'), {b_im}, {b_im_bram_del});
	
	if use_dsp48e
		xBlock( struct('source', str2func('negate_mux'), 'name', 'negate_mux'), ...
				{mux_latency, input_bit_width, input_bit_width-1}, ...
				{sel, b_re, b_im}, {bw_im_out} );
	else
		% block: twiddles_collections/twiddle_stage_2/delay3
		delay3 = xBlock(struct('source', 'Delay', 'name', 'delay3'), ...
							   struct('latency', mux_latency-1, 'reg_retiming', 'on'), {b_im_bram_del}, {delay3_out1});
		
		% block: twiddles_collections/twiddle_stage_2/delay4
		delay4 = xBlock(struct('source', 'Delay', 'name', 'delay4'), ...
					struct('latency', mux_latency-1, 'reg_retiming', 'on'), {convert_out1}, {delay4_out1});
				
		% bw_im = sel ? Imag(b*-j) : Imag(b) 
		mux1 = xBlock(struct('source', 'Mux', 'name', 'mux1'), ...
							 struct('latency', 1), {im_sel, delay3_out1, delay4_out1}, {bw_im_out});
		
		% negate bw_re to multiply by -j
		negate = xBlock(struct('source', 'Negate', 'name', 'negate'), ...
							   struct('n_bits', input_bit_width, 'bin_pt', input_bit_width-1, 'overflow', 'Saturate', ...
									  'latency', negate_latency-conv_latency), ...
							   {b_re}, {negate_out1});
		
		% convert data type of negate                 
		convert = xBlock(struct('source', 'Convert', 'name', 'convert'), ...
								struct('n_bits', input_bit_width, 'bin_pt', input_bit_width - 1, 'overflow', 'Saturate', ...
									   'latency', conv_latency, 'pipeline', 'on'), ...
								{negate_out1}, {convert_out1});                 
	end                       
						   
	% bw_re = sel ? Real(b*-j) : Real(b) 
	mux0 = xBlock(struct('source', 'Mux', 'name', 'mux0'), ...
						 struct('latency', mux_latency), {sel, b_re_bram_del, b_im_bram_del}, {bw_re_out});
						 
						 
end
