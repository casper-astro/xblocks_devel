%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda    Hong Chen  Terry Filiba  Aaron Parsons  %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fft_wideband_real_init_xblock(blk, varargin)
%depends  =
%{'pipeline_init_xblock','fft_biplex_real_4x_init_xblock','fft_direct_init_xblock','fft_unscrambler_init_xblock'}   
% todo 

% Set default vararg values.
defaults = { ...
    'FFTSize', 5, ...
    'n_inputs', 2, ...
    'input_bit_width', 18, ...
    'coeff_bit_width', 18,  ...
    'add_latency', 2, ...
    'mult_latency', 3, ...
    'bram_latency', 2, ...
    'conv_latency', 1, ...
    'input_latency', 0, ...
    'biplex_direct_latency', 0, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Saturate', ...
    'arch', 'Virtex5', ...
    'opt_target', 'logic', ...
    'coeffs_bit_limit', 8, ...
    'delays_bit_limit', 8, ...
    'specify_mult', 'on', ...
    'mult_spec', [1,1,1,1,1], ...
    'hardcode_shifts', 'off', ...
    'shift_schedule', [1 1 1 1 1], ...
    'dsp48_adders', 'on', ...
    'unscramble', 'on', ...
    'bit_growth_chart', [0 0 0 0 0], ...
    'negate_latency', 3, ...
    'negate_dsp48e', 1, ...
};

FFTSize = get_var('FFTSize', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
add_latency = 2; %get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
input_latency = get_var('input_latency', 'defaults', defaults, varargin{:});
biplex_direct_latency = get_var('biplex_direct_latency', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
arch = get_var('arch', 'defaults', defaults, varargin{:});
opt_target = get_var('opt_target', 'defaults', defaults, varargin{:});
coeffs_bit_limit = get_var('coeffs_bit_limit', 'defaults', defaults, varargin{:});
delays_bit_limit = get_var('delays_bit_limit', 'defaults', defaults, varargin{:});
specify_mult = get_var('specify_mult', 'defaults', defaults, varargin{:});
mult_spec = get_var('mult_spec', 'defaults', defaults, varargin{:});
hardcode_shifts = get_var('hardcode_shifts', 'defaults', defaults, varargin{:});
shift_schedule = get_var('shift_schedule', 'defaults', defaults, varargin{:});
dsp48_adders = get_var('dsp48_adders', 'defaults', defaults, varargin{:});
unscramble = get_var('unscramble', 'defaults', defaults, varargin{:});
bit_growth_chart = get_var('bit_growth_chart', 'defaults', defaults, varargin{:});
negate_latency = get_var('negate_latency', 'defaults', defaults, varargin{:});
negate_dsp48e = get_var('negate_dsp48e', 'defaults', defaults, varargin{:});
negate_dsp48e
%negate_dsp48e = strcmp(negate_dsp48e, 'on')

% deal with bit growth
% for bit growth FFT
bit_growth_chart =[reshape(bit_growth_chart, 1, []) zeros(1,FFTSize)];
bit_growth_biplex = 0;
for i=1:(FFTSize - n_inputs)
    bit_growth_biplex = bit_growth_biplex + bit_growth_chart(i);
end
bit_growth_sum = 0;
for i=1:FFTSize,
    bit_growth_sum = bit_growth_sum + bit_growth_chart(i);
end


% split up multiplier specification
mults_biplex = 2.*ones(1, FFTSize-n_inputs);
mults_direct = 2.*ones(1, n_inputs);


if strcmp(specify_mult, 'on'),
    if(length(mult_spec) ~= FFTSize)
        display('fft size must equal length of "specify multipliers"!');
        errordlg('fft size must equal length of "specify multipliers"!');
        error('fft size must equal length of "specify multipliers"!');
    end
    mults_biplex(1:FFTSize-n_inputs) = mult_spec(1: FFTSize-n_inputs);
    mults_direct = mult_spec(FFTSize-n_inputs+1:FFTSize);
end

% split up shift schedule
shifts_biplex = ones(1, FFTSize-n_inputs);
shifts_direct = ones(1, n_inputs);
if strcmp(hardcode_shifts, 'on'),
    shifts_biplex(1:FFTSize-n_inputs) = shift_schedule(1: FFTSize-n_inputs);
    shifts_direct = shift_schedule(FFTSize-n_inputs+1:FFTSize);
end


%% inports
sync = xInport('sync');
shift = xInport('shift');

direct_shift = xSignal;
% slice off shift bits for fft_direct
xBlock( struct('name', 'shift_slice', 'source', 'Slice'), ...
		struct('mode', 'Lower Bit Location + Width','bit0', FFTSize-n_inputs, 'nbits', n_inputs ), {shift}, {direct_shift} );

if n_inputs < 2
	error('fft_wideband_real: Must have at least 2^2 inputs!')
end

n_biplexes = 2^(n_inputs-2);
data_inports = {};
biplex_of_outputs = {};

direct_sync_in = xSignal;
direct_inputs = {direct_sync_in, direct_shift};

for k = 1:n_biplexes
	% declare input ports
	in_ports = {};
	for m = 1:4
		in_ports{m} = xInport(['din_', num2str( 4*(k-1)+m-1 )]);
	end
	
	% declare output ports
	out0_k = xSignal;	
	out1_k = xSignal;
	out2_k = xSignal;
	out3_k = xSignal;			
	sync_out = xSignal;
	of = xSignal;
	
	sync_del = xSignal;

	% delay input ports & sync by 'input_latency'
	xBlock( struct('source', str2func('pipeline_init_xblock'), 'name', ['in_del_sync_4x', num2str(k-1)]), ...
			{[blk,'/in_del_sync_4x', num2str(k-1)],input_latency}, {sync}, {sync_del} );

	biplex_in_ports = {sync_del, shift, xSignal, xSignal, xSignal, xSignal};
	for m = 1:4
		xBlock( struct('source', str2func('pipeline_init_xblock'), 'name', ['in_del_4x', num2str(k-1), 'pol', num2str(m)]), ...
				{[blk,'/in_del_4x', num2str(k-1), 'pol', num2str(m)],input_latency}, {in_ports{m}}, {biplex_in_ports{m+2}} );		
	end
	

	biplex_sync_out = xSignal;
	biplex_pol1_out = xSignal;
	biplex_pol2_out = xSignal;
	biplex_pol3_out = xSignal;
	biplex_pol4_out = xSignal;
	biplex_of_out = xSignal;
	% instantiate biplex core in xBlock form
	xBlock( struct('source', str2func('fft_biplex_real_4x_init_xblock'), 'name', ['fft_biplex_real_4x', num2str(k-1)]), ...
			{[blk,'/fft_biplex_real_4x', num2str(k-1) ],...
            'FFTSize', FFTSize-n_inputs, ...
			'input_bit_width', input_bit_width, ...
			'coeff_bit_width', coeff_bit_width, ...
			'add_latency', add_latency, ...
			'mult_latency', mult_latency, ...
			'bram_latency', bram_latency, ...
			'conv_latency', conv_latency, ...
			'negate_latency', negate_latency, ...
			'negate_dsp48e', negate_dsp48e, ...
			'quantization', quantization, ...
			'overflow', overflow, ...
			'arch', arch, ...
			'opt_target', opt_target, ...
			'coeffs_bit_limit', coeffs_bit_limit, ...
			'delays_bit_limit', delays_bit_limit, ...
			'specify_mult', specify_mult, ...
			'mult_spec', mults_biplex, ...
			'hardcode_shifts', hardcode_shifts, ...
			'shift_schedule', shifts_biplex, ...
			'dsp48_adders', dsp48_adders , ...
            'bit_growth_chart', bit_growth_chart, ...
            'Position', [170, 100, 290, 255], }, ...
	        biplex_in_ports, ...
	        {biplex_sync_out, biplex_pol1_out, biplex_pol2_out, biplex_pol3_out, biplex_pol4_out, biplex_of_out});
	
	biplex_of_outputs{k} = biplex_of_out;
	biplex_data_outputs = {biplex_pol1_out, biplex_pol2_out, biplex_pol3_out, biplex_pol4_out};
	biplex_data_outputs_del = {xSignal, xSignal, xSignal, xSignal};

	% TODO: delay the outports
	for m = 1:4
		xBlock( struct('source', str2func('pipeline_init_xblock'), 'name', ['out_del_4x', num2str(k-1), 'pol', num2str(m)]), ...
			{[blk,'/out_del_4x', num2str(k-1), 'pol', num2str(m) ], biplex_direct_latency}, { biplex_data_outputs{m} }, { biplex_data_outputs_del{m} } );	
	end
	
	if k == 1
		xBlock( struct('source', str2func('pipeline_init_xblock'), 'name', ['out_del_sync_4x', num2str(k-1)]), ...
			{[blk,'/out_del_sync_4x', num2str(k-1) ], biplex_direct_latency}, {biplex_sync_out}, {direct_sync_in} );
	end
	
	direct_inputs{4*k-3 + 2} = biplex_data_outputs_del{1};
	direct_inputs{4*k-2 + 2} = biplex_data_outputs_del{2};
	direct_inputs{4*k-1 + 2} = biplex_data_outputs_del{3};
	direct_inputs{4*k-0 + 2} = biplex_data_outputs_del{4};			
end


% Instantiate fft_direct block
direct_sync_out = xSignal;
direct_outports = {direct_sync_out};
for m = 1:2^(n_inputs)+1
	direct_outports{m+1} = xSignal;
end

xBlock( struct('name', 'fft_direct', 'source', str2func('fft_direct_init_xblock') ), ...
		{[blk, '/fft_direct'], ...
        'FFTSize', n_inputs, ...
		'input_bit_width', input_bit_width + bit_growth_biplex, ...
		'coeff_bit_width', coeff_bit_width + bit_growth_biplex, ...
		'map_tail', 'on', ...
		'LargerFFTSize', (FFTSize), ...
		'StartStage', (FFTSize-n_inputs+1), ...
		'add_latency', (add_latency), ...
		'mult_latency', (mult_latency), ...
		'bram_latency', (bram_latency), ...
		'conv_latency', (conv_latency), ...
		'quantization', (quantization), ...
		'overflow', (overflow), ...
		'arch', (arch), ...
		'opt_target', (opt_target), ...
		'coeffs_bit_limit', (coeffs_bit_limit), ...
		'specify_mult', (specify_mult), ...
		'mult_spec', (mults_direct), ...
		'hardcode_shifts', (hardcode_shifts), ...
		'shift_schedule', (shifts_direct), ...
		'dsp48_adders', (dsp48_adders), ...
        'bit_growth_chart',bit_growth_chart((FFTSize - n_inputs + 1):end)}, ...
		direct_inputs, direct_outports );

%
% Add output unscrambler.
%

sync_out = xOutport('sync_out');
fft_outports = {sync_out};
for n = 1:2^(n_inputs-1)
	fft_outports{n+1} = xOutport(['dout', num2str(n-1)]);
end

if strcmp(unscramble, 'on'),
    xBlock( struct('name', 'fft_unscrambler', 'source', str2func('fft_unscrambler_init_xblock')), ...
        {[blk,'/fft_unscrambler'], FFTSize-1,n_inputs-1, bram_latency}, ...
        {direct_outports{1:1+2^(n_inputs-1)}}, fft_outports);
else
    for i =1:length(fft_outports)
        fft_outports{i}.bind(direct_outports{i});
    end
end

% generate output overflow 
of_outputs = { biplex_of_outputs{:}, direct_outports{end} };
of = xOutport('of');
xBlock(struct('source', 'Logical', 'name', 'of_det'), ...
				struct('logical_function', 'OR', 'inputs', n_biplexes+1,'latency', 1), of_outputs, {of});


if ~isempty(blk) && ~strcmp(blk(1),'/')
    % Delete all unconnected blocks.
    clean_blocks(blk);

    %%%%%%%%%%%%%%%%%%%
    % Finish drawing. %
    %%%%%%%%%%%%%%%%%%%

    fmtstr = sprintf('%d stages\n(%d,%d)\n%s\n%s\n%s', FFTSize, input_bit_width, coeff_bit_width, quantization, overflow,num2str(bit_growth_chart,'%d '));
    set_param(blk, 'AttributesFormatString', fmtstr);
end

end

