%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda, Hong Chen                                 %
%   Copyright (C) 2007 Terry Filiba, Aaron Parsons                            %
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
function fft_biplex_core_init_xblock(blk, varargin)
% Valid varnames:
% FFTSize = Size of the FFT (2^FFTSize points).
% input_bit_width = Input and output bit width
% coeff_bit_width = Coefficient bit width
% quantization = Quantization behavior.
% overflow = Overflow behavior.
% add_latency = The latency of adders in the system.
% mult_latency = The latency of multipliers in the system.
% bram_latency = The latency of BRAM in the system.

%   depend: {'fft_stage_n_init_xblock'}
%
%                     'depend',{'fft_butterfly_init_xblock',...
%                                 'butterfly_arith_dsp48e_init_xblock',...
%                                 'fft_twiddle_init_xblock','simd_add_dsp48e_init_xblock',...
%                                 'simd_add_dsp48e_init_xblock','convert_of_init_xblock',...
%                                 'convert_of_init_xblock','c_to_ri_init_xblock','cmacc_dsp48e_init_xblock',...
%                                 'simd_add_dsp48e_init_xblock','coeff_gen_init_xblock'}
% {'barrel_switcher_init_xblock'}

disp('hello, welcome to fft_biplex_core(xblock)')
% Set default vararg values.
defaults = {'FFTSize', 2, ...
    'input_bit_width', 18, ...
    'coeff_bit_width', 18, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'overflow', 'Saturate', ...
    'add_latency', 1, ...
    'mult_latency', 2, ...
    'bram_latency', 2, ...
    'conv_latency', 1, ...
    'arch', 'Virtex5', ...
    'opt_target', 'logic', ...
    'coeffs_bit_limit', 8, ...
    'delays_bit_limit', 8, ...
    'specify_mult', 'off', ...
    'mult_spec', [2 2], ...
    'hardcode_shifts', 'off', ...
    'shift_schedule', [1 1], ...
    'dsp48_adders', 'off', ...
    'bit_growth_chart', [0 0]};

% Retrieve values from mask fields.
FFTSize = get_var('FFTSize', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
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
bit_growth_chart = get_var('bit_growth_chart', 'defaults', defaults, varargin{:});

if FFTSize < 2,
    errordlg('biplex_core_init.m: Biplex FFT must have length of at least 2^2, forcing size to 2.');
    FFTSize = 2;
end

if( strcmp(specify_mult, 'on') && (length(mult_spec) ~= FFTSize)),
    disp('biplex_core_init.m: Multiplier use specification for stages does not match FFT size');
    error('biplex_core_init.m: Multiplier use specification for stages does not match FFT size');
    return
end

% for bit growth FFT
bit_growth_chart =[reshape(bit_growth_chart, 1, []) zeros(1,FFTSize)];
bit_growth_chart

input_b_w = input_bit_width;
coeff_b_w = coeff_bit_width;

sync = xInport('sync');
shift = xInport('shift');
pol1 = xInport('pol1');
pol2 = xInport('pol2');

sync_out = xOutport('sync_out');
out1 = xOutport('out1');
out2 = xOutport('out2');
of = xOutport('of');



of_in = xSignal;

xBlock( struct('name', 'Constant', 'source', 'Constant'), ...
	{'arith_type', 'Boolean', 'const', 0, 'Position', [55 82 85 98]}, {}, {of_in}	);

% Create/Delete Stages
stage_inputs = {pol1, pol2, of_in, sync, shift};
for a=1:FFTSize,

	%if delays occupy larger space than specified then implement in BRAM
	if ((2^(FFTSize-a) * input_bit_width * 2) >= (2^delays_bit_limit)),
		delays_bram = 'on';
	else
		delays_bram = 'off';
	end

	%if coefficients occupy larger space than specified then store in BRAM
	if ((2^(a-1) * coeff_bit_width * 2) >= 2^coeffs_bit_limit),
		coeffs_bram = 'on';
	else
		coeffs_bram = 'off';
	end

	use_hdl = 'on';
	use_embedded = 'off';
	if strcmp(specify_mult, 'on'),
		if (mult_spec(a) == 2),
			use_hdl = 'on';
			use_embedded = 'off';
		elseif (mult_spec(a) == 1),
			use_hdl = 'off';
			use_embedded = 'on';
		else
			use_hdl = 'on';
			use_embedded = 'off';
		end
	end

	if (strcmp(hardcode_shifts, 'on') && (shift_schedule(a) == 1)),
		downshift = 'on';
	else
		downshift = 'off';
	end

	stage_name = ['fft_stage_',num2str(a)];

	stage_out1 = xSignal;
	stage_out2 = xSignal;
	stage_of = xSignal;
	stage_sync_out = xSignal;
	
	stage_outports = {stage_out1, stage_out2, stage_of, stage_sync_out};

	xBlock( struct('name', stage_name, 'source', str2func('fft_stage_n_init_xblock')), ...
		{ [blk,'/',stage_name], ...
			'FFTSize', FFTSize, ...
			'FFTStage', a, ...
			'input_bit_width', input_b_w, ...
			'coeff_bit_width', coeff_b_w, ...
			'downshift', downshift, ...
			'add_latency', add_latency, ...
			'mult_latency', mult_latency, ...
			'bram_latency', bram_latency, ...
			'conv_latency', conv_latency, ...
			'quantization', quantization, ...
			'overflow', overflow, ...
			'arch', arch, ...
			'opt_target', opt_target, ...
			'delays_bram', delays_bram, ...
			'coeffs_bram', coeffs_bram, ...
			'use_hdl', use_hdl, ...
			'use_embedded', use_embedded, ...
			'hardcode_shifts', hardcode_shifts, ...
			'dsp48_adders', dsp48_adders, ...
            'bit_growth', bit_growth_chart(a)}, ...
		stage_inputs, ...
		stage_outports );
	stage_inputs = stage_outports;
	stage_inputs{5} = shift;
    
    % for bit growth FFT
    input_b_w = input_b_w + bit_growth_chart(a);
    input_b_w
    coeff_b_w = coeff_b_w + bit_growth_chart(a);
    coeff_b_w
end

out1.bind( stage_inputs{1} );
out2.bind( stage_inputs{2} );
of.bind( stage_inputs{3} );
sync_out.bind( stage_inputs{4} );


if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    fmtstr = sprintf('%d stages\nreduce %s\n%s\n%s', FFTSize, opt_target, arch,num2str(bit_growth_chart,'%d '));
    set_param(blk, 'AttributesFormatString', fmtstr);
end

end