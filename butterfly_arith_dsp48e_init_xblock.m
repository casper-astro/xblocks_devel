function butterfly_arith_dsp48e_init_xblock(...
    Coeffs, StepPeriod, coeff_bit_width, input_bit_width, bram_latency,...
    conv_latency, quantization, overflow, arch, coeffs_bram, FFTSize)

%% inports
a = xInport('a');
b = xInport('b');
sync = xInport('sync');

%% outports
apbw_re_out = xOutport('a+bw_re');
apbw_im_out = xOutport('a+bw_im');
ambw_re_out = xOutport('a-bw_re');
ambw_im_out = xOutport('a-bw_im');
sync_out = xOutport('sync_out');

%% diagram
% parameters
total_latency = bram_latency + 4 + conv_latency;
add_latency = 2; % fixed for this implementation

% signals
w = xSignal;
w_re = xSignal;
w_im = xSignal;
b_re_del = xSignal;
b_im_del = xSignal;

% convert 'a' input to real/imag
a_re = xSignal;
a_im = xSignal;
c_to_ri_a = xBlock(struct('source', str2func('c_to_ri_init_xblock'), 'name', 'c_to_ri_a'), ...
    {input_bit_width, input_bit_width-1}, {a}, {a_re, a_im});

% convert 'b' input to real/imag
b_re = xSignal;
b_im = xSignal;
c_to_ri_b = xBlock(struct('source', str2func('c_to_ri_init_xblock'), 'name', 'c_to_ri_b'), ...
    {input_bit_width, input_bit_width-1}, {b}, {b_re, b_im});

a_re_del1 = xSignal;
a_im_del1 = xSignal;
a_re_del2 = xSignal;
a_im_del2 = xSignal;
a_re_del_scale = xSignal;
a_im_del_scale = xSignal;

apbw_re = xSignal;
apbw_im = xSignal;


% delay sync by total_latency 
sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
                       struct('latency', total_latency+add_latency), ...
                       {sync}, ...
                       {sync_out});

% delay a_re by total latency, with split for input to cmacc
a_re_delay = xBlock(struct('source', 'Delay', 'name', 'a_re_delay1'), ...
                       struct('latency', bram_latency, 'reg_retiming', 'on'), {a_re}, {a_re_del1});
a_re_delay = xBlock(struct('source', 'Delay', 'name', 'a_re_delay2'), ...
                       struct('latency', total_latency-bram_latency, 'reg_retiming', 'on'), {a_re_del1}, {a_re_del2});


% delay a_im by total latency 
a_im_delay = xBlock(struct('source', 'Delay', 'name', 'a_im_delay1'), ...
                       struct('latency', bram_latency, 'reg_retiming', 'on'), {a_im}, {a_im_del1});
a_im_delay = xBlock(struct('source', 'Delay', 'name', 'a_im_delay2'), ...
                       struct('latency', total_latency-bram_latency, 'reg_retiming', 'on'), {a_im_del1}, {a_im_del2});
                       
% Scale 'a' terms for subtraction input
xBlock( struct('source', 'Scale', 'name', 'a_re_scale'), struct('scale_factor', 1), {a_re_del2}, {a_re_del_scale});
xBlock( struct('source', 'Scale', 'name', 'a_im_scale'), struct('scale_factor', 1), {a_im_del2}, {a_im_del_scale});

% delay b_re by bram_latency 
b_re_delay = xBlock(struct('source', 'Delay', 'name', 'b_re_delay'), ...
                       struct('latency', bram_latency, 'reg_retiming', 'on'), {b_re}, {b_re_del});

% delay b_im by bram_latency 
b_im_delay = xBlock(struct('source', 'Delay', 'name', 'b_im_delay'), ...
                       struct('latency', bram_latency, 'reg_retiming', 'on'), {b_im}, {b_im_del});


% convert 'w' to real/imag 
c_to_ri_w = xBlock(struct('source', str2func('c_to_ri_init_xblock'), 'name', 'c_to_ri_w'), ...
                               {coeff_bit_width, coeff_bit_width-1}, {w}, {w_re, w_im});

% block: twiddles_collections/twiddle_general_dsp48e/cmult
cmacc_sub = xBlock(struct('source', str2func('cmacc_dsp48e_init_xblock'), 'name', 'apbw'), ...
                      {input_bit_width, input_bit_width - 1, coeff_bit_width, coeff_bit_width - 2, 'off', ...
                      	'off', input_bit_width + 5, input_bit_width + 1, quantization, ... 
                      	overflow, conv_latency}, ...
                      {b_re_del, b_im_del, w_re, w_im, a_re_del1, a_im_del1}, ...
                      {apbw_re, apbw_im});

apbw_re_out.bind( apbw_re );
apbw_im_out.bind( apbw_im );
                      
csub = xBlock(struct('source', str2func('simd_add_dsp48e_init_xblock'), 'name', 'csub'), ...
				  {'Subtraction', input_bit_width, input_bit_width-1, input_bit_width + 4, ...
						input_bit_width + 1, 'off', input_bit_width + 5, input_bit_width + 1, 'Truncate', 'Wrap', 0}, ...
				  {a_re_del_scale, a_im_del_scale, apbw_re, apbw_im}, ...
				  {ambw_re_out, ambw_im_out});                      

% instantiate coefficient generator
br_indices = bit_rev( Coeffs, FFTSize-1 );
br_indices = -2*pi*1j*br_indices/2^FFTSize;
ActualCoeffs = exp(br_indices);
coeff_gen_sub = xBlock(struct('source',str2func('coeff_gen_init_xblock'), 'name', 'coeff_gen'), ...
                          {ActualCoeffs, coeff_bit_width, StepPeriod, bram_latency, coeffs_bram}, {sync}, {w});
                          
end
