function fft_butterfly_init_xblock(varargin)

defaults = {'Coeffs', [0, j], ...
    'StepPeriod', 0, ...
    'input_bit_width', 18, ...
    'coeff_bit_width', 18,...
    'add_latency', 1, ...
    'mult_latency', 2, ...
    'conv_latency', 1, ...
    'bram_latency', 2, ...
    'input_latency', 0, ...
    'mux_latency',  5, ...
    'negate_latency', 3, ...
    'arch', 'Virtex5', ...
    'coeffs_bram', 'off', ...
    'use_hdl', 'off', ...
    'use_embedded', 'off', ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Wrap', ...
    'use_dsp48_mults', 0, ...
    'dsp48_adders', 1, ...
    'hardcode_shifts', 'off', ...
    'downshift', 'off', ...
    'opt_target', 'logic', ...
};
	
biplex = get_var('biplex', 'defaults', defaults, varargin{:});	
FFTSize = get_var('FFTSize', 'defaults', defaults, varargin{:});
Coeffs = get_var('Coeffs', 'defaults', defaults, varargin{:});
StepPeriod = get_var('StepPeriod', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});

add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
input_latency = get_var('input_latency', 'defaults', defaults, varargin{:});
mux_latency = get_var('mux_latency', 'defaults', defaults, varargin{:});
negate_latency = get_var('negate_latency', 'defaults', defaults, varargin{:});

arch = get_var('arch', 'defaults', defaults, varargin{:});
coeffs_bram = get_var('coeffs_bram', 'defaults', defaults, varargin{:});
use_hdl = get_var('use_hdl', 'defaults', defaults, varargin{:});
use_embedded = strcmp( get_var('use_embedded', 'defaults', defaults, varargin{:}), 'on' );
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
opt_target = get_var('opt_target', 'defaults', defaults, varargin{:});
use_dsp48_mults = get_var('use_dsp48_mults', 'defaults', defaults, varargin{:});
dsp48_adders = strcmp( get_var('dsp48_adders', 'defaults', defaults, varargin{:}), 'on');

hardcode_shifts = get_var('hardcode_shifts', 'defaults', defaults, varargin{:});
downshift = strcmp(get_var('downshift', 'defaults', defaults, varargin{:}), 'on');

if dsp48_adders
	add_latency = 2;
end

%% inports
a = xInport('a');
b = xInport('b');
sync = xInport('sync');
shift = xInport('shift');

%% outports
apbw = xOutport('a+bw');
ambw = xOutport('a-bw');
of = xOutport('of');
sync_out = xOutport('sync_out');

%% diagram



% instantiate twiddle
a_re = xSignal;
a_im = xSignal;
bw_re = xSignal;
bw_im = xSignal;
twiddle_sync_out = xSignal;
apbw_re = xSignal;
apbw_im = xSignal;
ambw_re = xSignal;
ambw_im = xSignal;

twiddle_out_sigs = {apbw_re, apbw_im, ambw_re, ambw_im};

apbw_re_ds = xSignal;
apbw_im_ds = xSignal;
ambw_re_ds = xSignal;
ambw_im_ds = xSignal;


twiddle_type = get_twiddle_type(Coeffs, biplex, opt_target, use_embedded);
gen_twiddles = {'twiddle_general_dsp48e', 'twiddle_general_4mult', 'twiddle_general_3mult'};
using_gen_twiddle = strcmp(twiddle_type, gen_twiddles);
five_dsp_butterfly = sum(dsp48_adders & use_embedded & using_gen_twiddle);

if five_dsp_butterfly
	arith = xBlock( struct('source', str2func('butterfly_arith_dsp48e_init_xblock'), 'name', 'arith'), ...
					{Coeffs, StepPeriod, coeff_bit_width, input_bit_width, bram_latency,...
				    conv_latency, quantization, overflow, arch, coeffs_bram, FFTSize}, ...
				    {a, b, sync}, ...
				    {apbw_re, apbw_im, ambw_re, ambw_im, twiddle_sync_out} );
	sync_latency = conv_latency;
				    
else 
	sync_latency = add_latency + conv_latency; 
	twiddle = xBlock(struct('source', str2func('fft_twiddle_init_xblock'), 'name', 'twiddle'), ...
									varargin, ...
									{a, b, sync}, ...
									{a_re, a_im, bw_re, bw_im, twiddle_sync_out});

	if dsp48_adders
		cadd = xBlock(struct('source', str2func('simd_add_dsp48e_init_xblock'), 'name', 'cadd'), ...
						  {'Addition', input_bit_width, input_bit_width-1, input_bit_width + 4, ...
								input_bit_width + 1, 'on', 19, 17, 'Truncate', 'Wrap', 0}, ...
						  {a_re, a_im, bw_re, bw_im}, ...
						  {apbw_re, apbw_im});
		
		csub = xBlock(struct('source', str2func('simd_add_dsp48e_init_xblock'), 'name', 'csub'), ...
						  {'Subtraction', input_bit_width, input_bit_width-1, input_bit_width + 4, ...
								input_bit_width + 1, 'on', 19, 17, 'Truncate', 'Wrap', 0}, ...
						  {a_re, a_im, bw_re, bw_im}, ...
						  {ambw_re, ambw_im});
	else
		% TODO! 
	end

end                  

% delay shift signal by 2 cycles---legacy
shift_del = xSignal;
xBlock( struct('source', 'Delay', 'name', 'shift_del'), struct('latency', 2), {shift}, {shift_del});


of_sigs = {};
conv_sigs = {};
for k = 1:4
	sig = twiddle_out_sigs{k};
	
	% downshift output signal
	sig_ds = xSignal;
	sig_var_ds = xSignal;	

	if ~strcmp(hardcode_shifts, 'on') 
		xBlock( struct('source', 'Scale', 'name', ['scale_', num2str(k)]), ...
				struct('scale_factor', -1), {sig}, {sig_ds} );
		% multiplex downshifted signal with direct output
		xBlock(struct('source', 'Mux', 'name', ['mux_', num2str(k)]), ...
					 struct('latency', 1), {shift_del, sig, sig_ds}, {sig_var_ds});

		% determine bit widths going into convert block
		conv_input_bit_width = input_bit_width + 6;
		conv_input_bin_pt = input_bit_width + 3;					 
					 
	else
		xBlock( struct('source', 'Scale', 'name', ['scale_', num2str(k)]), ...
				struct('scale_factor', -downshift), {sig}, {sig_ds} );	
		sig_var_ds = sig_ds;
		
		% determine bit widths going into convert block
		conv_input_bit_width = input_bit_width + 5;
		conv_input_bin_pt = input_bit_width + 2;		
	end
	
	% convert signals to specified output type
	conv_sig = xSignal;
	conv_sig_of = xSignal;
	if (k <= 2) & five_dsp_butterfly
		convert_of_latency = conv_latency + 2;
	else
		convert_of_latency = conv_latency;
	end
	

	
	convert_of1_sub = xBlock(struct('source', str2func('convert_of_init_xblock'), 'name', ['conv_of_', num2str(k)]), ...
								{conv_input_bit_width, conv_input_bin_pt, input_bit_width, input_bit_width-1, ...
								convert_of_latency, overflow, quantization}, {sig_var_ds}, {conv_sig, conv_sig_of});
	
	conv_sigs{k} = conv_sig;
	of_sigs{k} = conv_sig_of;
end

% OR the overflow signals together
xBlock(struct('source', 'Logical', 'name', 'Logical'), ...
	struct('logical_function', 'OR', 'inputs', 4), of_sigs, {of} );
	
	
% combine data signals into complex outputs
xBlock(struct('source', str2func('ri_to_c_init_xblock'), 'name', 'ri_to_c01'), ...
		  {}, { conv_sigs{1}, conv_sigs{2} }, {apbw});
xBlock(struct('source', str2func('ri_to_c_init_xblock'), 'name', 'ri_to_c23'), ...
		  {}, { conv_sigs{3}, conv_sigs{4} }, {ambw});

% delay sync from twiddle
if ~strcmp(hardcode_shifts, 'on') 
	sync_latency = sync_latency + 1;
end
sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
                           struct('latency', sync_latency, 'reg_retiming', 'on'), {twiddle_sync_out}, {sync_out});


end
