function twiddle_general_dsp48e_draw(a_re, a_im, b_re, b_im, sync, ...
    a_re_out, a_im_out, bw_re_out, bw_im_out, sync_out, ...
    Coeffs, StepPeriod, coeff_bit_width, input_bit_width, bram_latency,...
    conv_latency, quantization, overflow, arch, coeffs_bram, FFTSize)

%% diagram
% parameters
total_latency = bram_latency + 4 + conv_latency;

% signals
w = xSignal;
w_re = xSignal;
w_im = xSignal;
b_re_del = xSignal;
b_im_del = xSignal;


% delay sync by total_latency 
sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
                       struct('latency', total_latency), ...
                       {sync}, ...
                       {sync_out});

% delay a_re by total latency 
a_re_delay = xBlock(struct('source', 'Delay', 'name', 'a_re_delay'), ...
                       struct('latency', total_latency, 'reg_retiming', 'on'), {a_re}, {a_re_out});

% delay a_im by total latency 
a_im_delay = xBlock(struct('source', 'Delay', 'name', 'a_im_delay'), ...
                       struct('latency', total_latency, 'reg_retiming', 'on'), {a_im}, {a_im_out});

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
cmult_sub = xBlock(struct('source', str2func('cmult_dsp48e_init_xblock'), 'name', 'cmult'), ...
                      {input_bit_width, input_bit_width - 1, coeff_bit_width, coeff_bit_width - 2, 'off', ...
                      	'off', input_bit_width + 4, input_bit_width + 1, quantization, ... 
                      	overflow, conv_latency}, ...
                      {b_re_del, b_im_del, w_re, w_im}, ...
                      {bw_re_out, bw_im_out});

% instantiate coefficient generator
br_indices = bit_rev( Coeffs, FFTSize-1 );
br_indices = -2*pi*1j*br_indices/2^FFTSize;
ActualCoeffs = exp(br_indices);
coeff_gen_sub = xBlock(struct('source',str2func('coeff_gen_init_xblock'), 'name', 'coeff_gen'), ...
                          {ActualCoeffs, coeff_bit_width, StepPeriod, bram_latency, coeffs_bram}, {sync}, {w});
                          
end
