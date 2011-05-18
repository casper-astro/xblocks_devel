function fft_direct_init_xblock(varargin)

% Set default vararg values.
defaults = { ...
    'FFTSize', 2,  ...
    'input_bit_width', 18, ...
    'coeff_bit_width', 18, ...
    'map_tail', 'on', ...
    'LargerFFTSize', 5, ...
    'StartStage', 4, ...
    'add_latency', 2, ...
    'mult_latency', 3, ...
    'bram_latency', 2, ...
    'conv_latency', 1, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Saturate', ...
    'arch', 'Virtex5', ...
    'opt_target', 'logic', ...
    'coeffs_bit_limit', 8,  ...
    'specify_mult', 'on', ...
    'mult_spec', [1,1], ...
    'hardcode_shifts', 'off', ...
    'shift_schedule', [1], ...
    'dsp48_adders', 'on', ...
};


% Retrieve values from mask fields.
FFTSize = get_var('FFTSize', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
map_tail = get_var('map_tail', 'defaults', defaults, varargin{:});
LargerFFTSize = get_var('LargerFFTSize', 'defaults', defaults, varargin{:});
StartStage = get_var('StartStage', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
arch = get_var('arch', 'defaults', defaults, varargin{:});
opt_target = get_var('opt_target', 'defaults', defaults, varargin{:});
coeffs_bit_limit = get_var('coeffs_bit_limit', 'defaults', defaults, varargin{:});
specify_mult = get_var('specify_mult', 'defaults', defaults, varargin{:});
mult_spec = get_var('mult_spec', 'defaults', defaults, varargin{:});
hardcode_shifts = get_var('hardcode_shifts', 'defaults', defaults, varargin{:});
shift_schedule = get_var('shift_schedule', 'defaults', defaults, varargin{:});
dsp48_adders = get_var('dsp48_adders', 'defaults', defaults, varargin{:});
biplex = get_var('biplex', 'defaults', defaults, varargin{:});

if (strcmp(specify_mult, 'on') && (length(mult_spec) ~= FFTSize)),
    error('fft_direct_init.m: Multiplier use specification for stages does not match FFT size');
end

%% Declare Ports
sync = xInport('sync');
shift = xInport('shift');

sync_out = xOutport('sync_out');
data_inports = {};
data_outports = {};
for k=0:2^FFTSize-1,
	data_inports{k+1} = xInport(['din_' num2str(k)]);
	data_outports{k+1} = xOutport(['dout_' num2str(k)]);
end

of = xOutport('of');
of_outports = {};


% Add nodes
node_inputs = {};
node_outputs = {};
bf_shifts = {};
for stage=0:FFTSize,
	stage
    for i=0:2^FFTSize-1,
        node_name = ['node',num2str(stage),'_',num2str(i)];
        pos = [300*stage+90 100*i+100 300*stage+120 100*i+130];
        
        node_in = xSignal;
        node_out = xSignal;
        if stage == 0
			xBlock( struct('source', 'Delay', 'name', node_name), struct('latency', 0, 'Position', pos), ...
					{data_inports{i+1}}, {node_out});        	
        elseif stage == FFTSize
			xBlock( struct('source', 'Delay', 'name', node_name), struct('latency', 0, 'Position', pos), ...
					{node_in}, {data_outports{bit_reverse(i, FFTSize)+1}});
        else
			xBlock( struct('source', 'Delay', 'name', node_name), struct('latency', 0, 'Position', pos), ...
					{node_in}, {node_out});
		end
        node_inputs{stage+1, i+1} = node_in;
        node_outputs{stage+1, i+1} = node_out;
    end

	% slice off shift bits for each butterfly 
    if (stage ~= FFTSize),
    	stage_shift = xSignal;
        shift_slice_name = ['slice',num2str(stage)]
        pos = [300*stage+90 70 300*stage+120 85];
        xBlock( struct('source', 'Slice', 'name', shift_slice_name), ...
        		struct('Position', pos, 'mode', 'Lower Bit Location + Width', 'nbits', 1, ...
					   'bit0', stage, 'boolean_output', 'on'), {shift}, {stage_shift});
		bf_shifts{stage+1} = stage_shift;
    end
end


% initialize bf_syncs
bf_syncs = {};
for stage=0:FFTSize,
	for i=0:2^(FFTSize-1)-1
		if stage == 0
			bf_syncs{stage+1, i+1} = sync;
		else
			bf_syncs{stage+1, i+1} = xSignal;
		end
	end
end

stage_of_out = {};

% Add butterflies
for stage=1:FFTSize,
    use_hdl = 'on';
    use_embedded = 'off';
    if strcmp(specify_mult, 'on'),
        if (mult_spec(stage) == 2),
            use_hdl = 'on';
            use_embedded = 'off';
        elseif (mult_spec(stage) == 1),
            use_hdl = 'off';
            use_embedded = 'on';
        else
            use_hdl = 'off';
            use_embedded = 'off';
        end
    end

    if (strcmp(hardcode_shifts, 'on') && (shift_schedule(stage) == 1)),
        downshift = 'on';
    else
        downshift = 'off';
    end


	stage_of_outputs = {};

    for i=0:2^(FFTSize-1)-1,
    	stage, i
        % Implement a normal FFT or the tail end of a larger FFT
        if strcmp(map_tail, 'off'),
            coeffs = [ floor(i/2^(FFTSize-stage)) ];
            actual_fft_size = FFTSize;
            num_coeffs = 1;
        else
            redundancy = 2^(LargerFFTSize - FFTSize);
            coeffs = [];
            for r=0:redundancy-1,
                n = bit_reverse(r, LargerFFTSize - FFTSize);
                coeffs = [coeffs, floor((i+n*2^(FFTSize-1))/2^(LargerFFTSize-(StartStage+stage-1)))];
            end
            actual_fft_size = LargerFFTSize;
            num_coeffs = redundancy;
        end

        if ((num_coeffs * coeff_bit_width * 2) > 2^coeffs_bit_limit),
            coeffs_bram = 'on';
        else
            coeffs_bram = 'off';
        end

        bf_name = ['butterfly', num2str(stage), '_', num2str(i)];
        bf_pos = [300*(stage-1)+220 200*i+100 300*(stage-1)+300 200*i+175];
        node_one_num = 2^(FFTSize-stage+1)*floor(i/2^(FFTSize-stage)) + mod(i, 2^(FFTSize-stage))
        node_two_num = node_one_num+2^(FFTSize-stage)
        
        bf_inputs = { node_outputs{stage, node_one_num+1}, node_outputs{stage, node_two_num+1}, ...
        	bf_syncs{stage, i+1}, bf_shifts{stage} };
        	
        bf_sync_out = xSignal;
        of_out = xSignal;
        node_inputs{stage, node_one_num+1}, node_inputs{stage, node_two_num+1}
        bf_outputs = { node_inputs{stage+1, node_one_num+1}, node_inputs{stage+1, node_two_num+1}, ...
        	of_out, bf_syncs{stage+1, i+1} };        

		coeffs
        xBlock( struct('source', str2func('fft_butterfly_init_xblock'), 'name', bf_name), ...
            {'Position', bf_pos, 'biplex', 'off', ...
            'FFTSize', actual_fft_size, ...
            'Coeffs', coeffs, ...
            'StepPeriod', 0, ...
            'coeff_bit_width', coeff_bit_width, ...
            'input_bit_width', input_bit_width, ...
            'downshift', downshift, ...
            'bram_latency', bram_latency, ...
            'add_latency', add_latency, ...
            'mult_latency', mult_latency, ...
            'conv_latency', conv_latency, ...
            'quantization', quantization, ...
            'overflow', overflow, ...
            'arch', arch, ...
            'opt_target', opt_target, ...
            'coeffs_bram', coeffs_bram, ...
            'use_hdl', use_hdl, ...
            'use_embedded', use_embedded, ...
            'hardcode_shifts', hardcode_shifts, ...
            'dsp48_adders', dsp48_adders}, ...
            bf_inputs, bf_outputs );
		
		stage_of_outputs{i+1} = of_out;
    end

	%add overflow logic
	of_out = xSignal;
	pos = [300*stage+90 100*(2^FFTSize)+100+(stage*15) 300*stage+120 120+100*(2^FFTSize)+(FFTSize*5)+(stage*15)];
	xBlock( struct('name', ['of_', num2str(stage)], 'source', 'Logical'), ...
			{'Position', pos, 'logical_function', 'OR', 'inputs', 2^(FFTSize-1), 'latency', 1}, ...
			stage_of_outputs, {of_out});
	stage_of_out{stage} = of_out;
end


%FFTSize == 1 implies 1 input or block which generates an error
if (FFTSize ~= 1),
    pos = [300*FFTSize+150 100*(2^FFTSize)+100 300*FFTSize+180 100*(2^FFTSize)+115+(FFTSize*10)];
    xBlock( struct('name', 'of_or', 'source', 'Logical'), ...
			{'Position', pos, ...
			'logical_function', 'OR', ...
			'inputs', FFTSize, ...
			'latency', 0}, stage_of_out, {of});
end

% Connect sync_out
sync_out.bind( bf_syncs{FFTSize+1, 1} );

end
