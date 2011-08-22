%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda, Hong Chen                                 %
%   Copyright (C) 2010 William Mallard                                        %
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
function fft_butterfly_init_xblock(blk, varargin)
%'depend',{'butterfly_arith_dsp48e_init_xblock',...
%         'fft_twiddle_init_xblock','simd_add_dsp48e_init_xblock',...
%         'simd_add_dsp48e_init_xblock','convert_of_init_xblock', ...
%         'convert_of_init_xblock'}
%
% {'c_to_ri_init_xblock','cmacc_dsp48e_init_xblock','simd_add_dsp48e_init_xblock','coeff_gen_init_xblock'}

defaults = {'Coeffs', [0 1], ...
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
    'bit_growth', 0, ...
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
mux_latency = get_var('mux_latency', 'defaults', defaults, varargin{:});  % really need this?
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
bit_growth = get_var('bit_growth', 'defaults', defaults, varargin{:});
bit_growth




% Validate input fields.

if ~strcmp(arch, 'Virtex5') && strcmp(dsp48_adders, 'on'),
    fprintf('butterfly_direct_init: Cannot use dsp48e adders on a non-Virtex5 chip.\n');
    clog(['butterfly_direct_init: Cannot use dsp48e adders on a non-Virtex5 chip.\n'], 'error');
end

if strcmp(coeffs_bram, 'on'),
    coeff_type = 'BRAM';
else
    coeff_type = 'slices';
end

if strcmp(hardcode_shifts, 'on'),
    mux_latency = 0;
else
    mux_latency = 1;
end

if dsp48_adders,
    add_latency = 2;
end


% Compute the complex, bit-reversed values of the twiddle factors
br_indices = bit_rev(Coeffs, FFTSize-1);
br_indices = -2*pi*1j*br_indices/2^FFTSize;
ActualCoeffs = exp(br_indices);




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


twiddle_type = get_twiddle_type(Coeffs, biplex, opt_target, use_embedded,StepPeriod,FFTSize);
gen_twiddles = {'twiddle_general_dsp48e', 'twiddle_general_4mult', 'twiddle_general_3mult'};
using_gen_twiddle = strcmp(twiddle_type, gen_twiddles);
five_dsp_butterfly = sum(dsp48_adders & use_embedded & using_gen_twiddle);

% Compute bit widths into addsub and convert blocks.
bw = input_bit_width + 7;
bd = input_bit_width + 2;
if strcmp(twiddle_type, 'twiddle_general_3mult'),
    bw = input_bit_width + 7;
    bd = input_bit_width + 2;
elseif strcmp(twiddle_type, 'twiddle_general_4mult') || strcmp(twiddle_type, 'twiddle_general_dsp48e'),
    bw = input_bit_width + 6;
    bd = input_bit_width + 2;
elseif strcmp(twiddle_type, 'twiddle_stage_2') ...
    || strcmp(twiddle_type, 'twiddle_coeff_0') ...
    || strcmp(twiddle_type, 'twiddle_coeff_1') ...
    || strcmp(twiddle_type, 'twiddle_pass_through'),
    bw = input_bit_width + 2;
    bd = input_bit_width;
else
    fprintf('butterfly_direct_init: Unknown twiddle %s\n', twiddle_type);
    clog(['butterfly_direct_init: Unknown twiddle ', twiddle_type', '\n'], 'error');
end

addsub_b_bitwidth = bw - 2;
addsub_b_binpoint = bd - 1;

if strcmp(hardcode_shifts, 'on'),
    if strcmp(downshift, 'on'),
        convert_in_bitwidth = bw - 1;
        convert_in_binpoint = bd;
    else
        convert_in_bitwidth = bw - 1;
        convert_in_binpoint = bd - 1;
    end
else
    convert_in_bitwidth = bw;
    convert_in_binpoint = bd;
end

if five_dsp_butterfly
	arith = xBlock( struct('source', str2func('butterfly_arith_dsp48e_init_xblock'), 'name', 'arith'), ...
					{[blk,'/arith'], Coeffs, StepPeriod, coeff_bit_width, input_bit_width, bram_latency,...
				    conv_latency, quantization, overflow, arch, coeffs_bram, FFTSize}, ...
				    {a, b, sync}, ...
				    {apbw_re, apbw_im, ambw_re, ambw_im, twiddle_sync_out} );
	sync_latency = conv_latency;
				    
else 
	sync_latency = add_latency + conv_latency; 
	twiddle = xBlock(struct('source', str2func('fft_twiddle_init_xblock'), 'name', 'twiddle'), ...
									[{[blk,'/twiddle']}, varargin,{'ActualCoeffs',ActualCoeffs}], ...
									{a, b, sync}, ...
									{a_re, a_im, bw_re, bw_im, twiddle_sync_out});

	if dsp48_adders
		cadd = xBlock(struct('source', str2func('simd_add_dsp48e_init_xblock'), 'name', 'cadd'), ...
						  {[blk,'/cadd'], 'Addition', input_bit_width, input_bit_width-1, input_bit_width + 4, ...
								input_bit_width + 1, 'on', 19, 17, 'Truncate', 'Wrap', 0}, ...
						  {a_re, a_im, bw_re, bw_im}, ...
						  {apbw_re, apbw_im});
		
		csub = xBlock(struct('source', str2func('simd_add_dsp48e_init_xblock'), 'name', 'csub'), ...
						  {[blk,'/csub'],'Subtraction', input_bit_width, input_bit_width-1, input_bit_width + 4, ...
								input_bit_width + 1, 'on', 19, 17, 'Truncate', 'Wrap', 0}, ...
						  {a_re, a_im, bw_re, bw_im}, ...
						  {ambw_re, ambw_im});
	else
		% TODO! 
        AddSub = cell(1,4);
        
        AddSub{1} = xBlock(struct('source', 'AddSub', 'name', 'AddSub0'), ...
                           struct('mode', 'Addition', ...
                                  'latency', add_latency, ...
                                  'precision','Full',...
                                  'use_behavioral_HDL', 'on'), ...
                           {a_re,bw_re}, ...
                           {apbw_re});
        AddSub{2} = xBlock(struct('source', 'AddSub', 'name', 'AddSub1'), ...
                   struct('mode', 'Addition', ...
                          'latency', add_latency, ...
                          'precision','Full',...
                          'use_behavioral_HDL', 'on'), ...
                   {a_im,bw_im}, ...
                   {apbw_im});


        AddSub{3} = xBlock(struct('source', 'AddSub', 'name', 'AddSub2'), ...
                           struct('mode', 'Subtraction', ...
                                  'latency', add_latency, ...
                                  'precision','Full',...
                                  'use_behavioral_HDL', 'on'), ...
                           {a_re,bw_re}, ...
                           {ambw_re});
        AddSub{4} = xBlock(struct('source', 'AddSub', 'name', 'AddSub3'), ...
                           struct('mode', 'Subtraction', ...
                                  'latency', add_latency, ...
                                  'precision','Full',...
                                  'use_behavioral_HDL', 'on'), ...
                           {a_im,bw_im}, ...
                           {ambw_im});

	end

end                  


if strcmp(hardcode_shifts,'off')
    % delay shift signal by 2 cycles---legacy 
    shift_del = xSignal;
    xBlock( struct('source', 'Delay', 'name', 'shift_del'), struct('latency', 2), {shift}, {shift_del});
else
    xBlock( struct('source','built-in/terminator','name','Terminator'),...
            struct('Position', [400 20 420 40], ...
                    'ShowName', 'off'),...
                    {shift}, {});
                    
end

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
		%conv_input_bit_width = input_bit_width + 6;
		%conv_input_bin_pt = input_bit_width + 3;					 
		% (doesn't seem to be right)			 
    else

        xBlock( struct('source', 'Scale', 'name', ['scale_', num2str(k)]), ...
                    struct('scale_factor', -downshift), {sig}, {sig_ds} );	
        sig_var_ds = sig_ds;
        
        % determine bit widths going into convert block
        %conv_input_bit_width = input_bit_width + 5;
        %conv_input_bin_pt = input_bit_width + 2; 
        % (doesn't seem to be right)
	end
	
	% convert signals to specified output type
	conv_sig = xSignal;
	conv_sig_of = xSignal;
	if (k <= 2) & five_dsp_butterfly
		convert_of_latency = conv_latency + 2;
	else
		convert_of_latency = conv_latency;
	end
	

	
	%convert_of1_sub = xBlock(struct('source', str2func('convert_of_init_xblock'), 'name', ['conv_of_', num2str(k)]), ...
	%							{conv_input_bit_width, conv_input_bin_pt, input_bit_width+bit_growth, input_bit_width-1+bit_growth, ...
	%							convert_of_latency, overflow, quantization}, {sig_var_ds}, {conv_sig, conv_sig_of});
	convert_of1_sub = xBlock(struct('source', str2func('convert_of_init_xblock'), 'name', ['conv_of_', num2str(k)]), ...
								{[blk,'/','conv_of_', num2str(k)], convert_in_bitwidth, ...
                                 convert_in_binpoint, input_bit_width+bit_growth, input_bit_width-1+bit_growth, ...
								 convert_of_latency, overflow, ...
								 quantization}, {sig_var_ds}, {conv_sig, conv_sig_of});
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

if ~isempty(blk) && ~strcmp(blk(1), '/')
    % Delete all unconnected blocks.
    clean_blocks(blk);

    %%%%%%%%%%%%%%%%%%%
    % Finish drawing! %
    %%%%%%%%%%%%%%%%%%%

    % Set attribute format string (block annotation).
    fmtstr = sprintf('%s\ncoeffs in %s\nBit growth:%d', twiddle_type, coeff_type, bit_growth);
    set_param(blk, 'AttributesFormatString', fmtstr);
end


end
