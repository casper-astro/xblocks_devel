function latencies = get_biplex_stage_latencies(varargin)

disp('biplex stage latencies calculations');
FFTSize = get_var('FFTSize', varargin{:})
mux_latency = 1; %get_var('mux_latency', varargin{:})
hardcode_shifts = get_var('hardcode_shifts', varargin{:})
conv_latency = get_var('conv_latency', varargin{:})
bram_latency = get_var('bram_latency', varargin{:})
input_latency = 0
mult_latency = get_var('mult_latency', varargin{:})
dsp48_adders = get_var('dsp48_adders', varargin{:})
mult_spec = get_var('mult_spec', varargin{:})
add_latency = get_var('add_latency', varargin{:})
opt_target = get_var('opt_target', varargin{:})

latencies = zeros(1, FFTSize);


gen_twiddles = {'twiddle_general_dsp48e', 'twiddle_general_4mult', 'twiddle_general_3mult'};



for stage=1:FFTSize
	stage_sync_del = 2^(FFTSize-stage)+mux_latency;
	if strcmp(hardcode_shifts, 'on')
		shift_latency = 0;
	else
		shift_latency = 1;
	end
	
	if(stage == 1 ),
		Coeffs = 0;
	else
		Coeffs = 0:2^(stage-1)-1;
	end	

	biplex = 'on'; % not specified as var in biplex core
	use_embedded = (mult_spec(stage) == 1);
	
	if use_embedded
		use_embedded = 'on';
	end
	
	StepPeriod = FFTSize-stage;
	
	
	twiddle_type = get_twiddle_type(Coeffs, biplex, opt_target, use_embedded, ...
		StepPeriod, FFTSize);
	using_gen_twiddle = strcmp(twiddle_type, gen_twiddles)
	five_dsp_butterfly = sum(dsp48_adders & strcmp(use_embedded, 'on') & sum(using_gen_twiddle));
	
	
	if strcmp(twiddle_type, 'twiddle_pass_through')
		twiddle_latency = 0;
	elseif strcmp(twiddle_type, 'twiddle_stage_2')
		if(strcmp(opt_target, 'logic')), 
			lat = add_latency;
		else
			lat = add_latency*2;
		end
		twiddle_latency = bram_latency + mult_latency+conv_latency+lat;
	elseif five_dsp_butterfly
		twiddle_latency = bram_latency + 4 + conv_latency + 2;
	end
	
	if five_dsp_butterfly
		bf_add_latency = 0;
	else
		bf_add_latency = add_latency;
	end
	
	latencies(stage) = stage_sync_del + input_latency + shift_latency + conv_latency ...
		+ bf_add_latency + twiddle_latency;
end		
