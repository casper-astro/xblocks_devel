%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda                                            %
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
function pfb_row_init_xblock(blk, varargin)

defaults = {'nput', 0, ...
	'PFBSize', 5, ...
	'TotalTaps', 2, ...
    'WindowType', 'hamming', ...
    'n_inputs', 1, ...
    'MakeBiplex', 0, ...
    'BitWidthIn', 8, ...
    'BitWidthOut', 18, ...
    'CoeffBitWidth', 18, ...
    'CoeffDistMem', 0, ...
    'add_latency', 1, ...
    'mult_latency', 2, ...
    'bram_latency', 2, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'fwidth', 1, ...
    'specify_mult', 'off', ...
    'mult_spec', [2 2], ...
    'adder_tree_impl', 'Behavioral', ...
    'mult_impl', 'Fabric', ...
    'input_latency', 0, ...
    'input_type', 'Complex', ...
    'biplex_inputs', 1, ...
    'use_hdl', 'on', ...
    'use_embedded', 'off', ...
    'conv_latency', 1};    

nput = get_var('nput', 'defaults', defaults, varargin{:});
PFBSize = get_var('PFBSize', 'defaults', defaults, varargin{:});
TotalTaps = get_var('TotalTaps', 'defaults', defaults, varargin{:});
WindowType = get_var('WindowType', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
MakeBiplex = get_var('MakeBiplex', 'defaults', defaults, varargin{:});
BitWidthIn = get_var('BitWidthIn', 'defaults', defaults, varargin{:});
BitWidthOut = get_var('BitWidthOut', 'defaults', defaults, varargin{:});
CoeffBitWidth = get_var('CoeffBitWidth', 'defaults', defaults, varargin{:});
CoeffDistMem = get_var('CoeffDistMem', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
fwidth = get_var('fwidth', 'defaults', defaults, varargin{:});
specify_mult = get_var('specify_mult', 'defaults', defaults, varargin{:});
mult_spec = get_var('mult_spec', 'defaults', defaults, varargin{:});
adder_tree_impl = get_var('adder_tree_impl', 'defaults', defaults, varargin{:});
mult_impl = get_var('mult_impl', 'defaults', defaults, varargin{:});
input_latency = get_var('input_latency', 'defaults', defaults, varargin{:});
input_type = get_var('input_type', 'defaults', defaults, varargin{:});

biplex_inputs = get_var('biplex_inputs', 'defaults', defaults, varargin{:}); % repeat? MakeBiplex
use_hdl = get_var('use_hdl', 'defaults', defaults, varargin{:});
use_embedded = get_var('use_embedded', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});


MakeBiplex


%% inports

complex_inputs = strcmp(input_type, 'Complex');

if ~biplex_inputs
    din = xInport('din');
    coeff_gen_din = din;
elseif biplex_inputs
    din1 = xInport('din_pol1');
    din2 = xInport('din_pol2');
    coeff_gen_din = xSignal;
    xBlock( struct('source', str2func('cram_init_xblock'), 'name', 'comb_data'), ...
        {[blk,'/comb_data'], 2}, ...
        {din1, din2}, {coeff_gen_din});
end
    
sync = xInport('sync');

%% outports
sync_out = xOutport('sync_out');

if biplex_inputs
    out1 = xOutport('out1');
    out2 = xOutport('out2');
else
    out = xOutport('out');
end

%% diagram

coeff_gen_dout = xSignal;
delay_bram_out1 = xSignal;

coeff_gen_sync_out = xSignal;
sync_delay_adder_tree = xSignal;
delay0_dout = xSignal;
sync_delay_out2 = xSignal;
coeff_gen_outports = {coeff_gen_dout, coeff_gen_sync_out};
for k=1:TotalTaps,
    coeff_gen_outports{k+2} = xSignal;
end

% block: dsp48e_pfb_test2/pfb_row/scale_1_1
macc_dsp48e_2in_0_out1 = xSignal;
scale_factor = 1 + nextpow2(TotalTaps);





% block: dsp48e_pfb_test2/pfb_row/delay_bram

% Coefficient Generator
coeff_gen_config.source = str2func('pfb_coeff_gen_init_xblock');
coeff_gen_config.name = 'pfb_coeff_gen';
pfb_coeff_gen_sub = xBlock(coeff_gen_config, ...
    {[blk,'/',coeff_gen_config.name],PFBSize, CoeffBitWidth, TotalTaps, ...
    CoeffDistMem, WindowType, bram_latency, n_inputs, ...
    nput, fwidth});
pfb_coeff_gen_sub.bindPort({coeff_gen_din, sync}, coeff_gen_outports);

%% Mult sync delay
if strcmp(mult_impl, 'DSP48e')
	sync_delay_per = 2^(PFBSize-n_inputs) * (TotalTaps-1) + mult_latency + 1;
elseif 	strcmp(mult_impl, 'Fabric')
    sync_delay_per = 2^(PFBSize-n_inputs) * (TotalTaps-1) + mult_latency;
end

sync_delay_config.source = str2func('sync_delay_init_xblock');
sync_delay_config.name = 'sync_delay';
sync_delay = xBlock( sync_delay_config, ...
    {[blk,'/',sync_delay_config.name],sync_delay_per}, ...
    {coeff_gen_sync_out}, ...
    {sync_delay_adder_tree});


% Route data signals through delay BRAMs
delay_out_sigs = {coeff_gen_dout};
delay_k_out = xSignal;
for k = 2:TotalTaps,
    delay_km1_out = delay_k_out;
    delay_k_out = xSignal;
    bram1_config.source = str2func('delay_bram_init_xblock');
    bram1_config.name = ['delay_bram', num2str(k)];
    delay1 = xBlock(bram1_config, {[blk,'/',bram1_config.name], 2^(PFBSize-n_inputs)*1, bram_latency, 'on'});
    delay1.bindPort({delay_out_sigs{k-1}}, {delay_k_out});
    delay_out_sigs{k} = delay_k_out;
end

% Split data inputs
if ~complex_inputs && ~biplex_inputs
	num_data_slices = 1;
	adder_tree_outports = {out};
elseif ~complex_inputs && biplex_inputs
	num_data_slices = 2;
	adder_tree_outports = {out1, out2};
elseif complex_inputs && ~biplex_inputs
	num_data_slices = 2;
	adder_tree_outports = {xSignal, xSignal};
elseif complex_inputs && biplex_inputs
	num_data_slices = 4;
	adder_tree_outports = {xSignal, xSignal, xSignal, xSignal};	
end

macc_ports = {};
for n = 1:num_data_slices
	macc_ports_n = {};
	for k = 1:TotalTaps
		macc_ports_n{2*k-1} 	= coeff_gen_outports{k+2};
		macc_ports_n{2*k}		= xSignal;
	end
	macc_ports{n} = macc_ports_n;
end

for k=1:TotalTaps
	% split delay_out_sigs{k} into imag/real biplex components

	tap_split_k_outports = {};
	for n = 1:num_data_slices
		macc_ports_n = macc_ports{n};
		tap_split_k_outports{n} = macc_ports_n{2*k};
	end
	
	xBlock( struct('source', str2func('uncram_init_xblock'), 'name', ['tap_split_', num2str(k)]), ...
			{[blk, '/','tap_split_', num2str(k)], 'num_slice', num_data_slices, ...
                'slice_width', BitWidthIn, 'bin_pt', BitWidthIn-1, 'arith_type', 1}, ...
		{ delay_out_sigs{k} }, tap_split_k_outports );
     
end

if strcmp(mult_impl, 'DSP48e')
	num_adder_tree_inports = ceil(TotalTaps/2);
	mult_source_func = str2func('macc_dsp48e_init_xblock');
else
	num_adder_tree_inports = TotalTaps;	
	mult_source_func = str2func('tap_multiply_fabric_init_xblock');		
end

for k = 1:num_data_slices
	sync_delay_out = xSignal;
	add_tree_out = xSignal;
	adder_tree_inports = {sync_delay_adder_tree};
	for n=1:num_adder_tree_inports
		mult_outports{n} = xSignal;
		adder_tree_inports{n+1} = mult_outports{n};
	end
	
	% instantiate N-input MACC
	mult_block_config.source = mult_source_func;
	mult_block_config.name = ['mult', num2str(k)];
	mult_block_config.depend = {'macc_dsp48e_init_xblock.m', 'tap_multiply_fabric_init_xblock.m'};
	mult_block = xBlock(mult_block_config,...
        {[blk,'/',mult_block_config.name], CoeffBitWidth, CoeffBitWidth-1, BitWidthIn, ...
		BitWidthIn-1, 'on', CoeffBitWidth+BitWidthIn+1, CoeffBitWidth+BitWidthIn-2, 'Truncate', ...
		'Wrap', 0, TotalTaps, mult_latency});
		
	mult_block.bindPort( macc_ports{k}, mult_outports);
	
	% instantiate N-input adder tree
	adder_tree_config.source = str2func('adder_tree_init_xblock');
	adder_tree_config.name = ['adder_tree', num2str(k)];
	adder_tree_config.depend = {'adder_tree_init_xblock.m'};
	adder_tree_block = xBlock( adder_tree_config,...
        {[blk, '/',adder_tree_config.name], 'n_inputs', num_adder_tree_inports, ...
        'add_latency', add_latency, 'quantization', quantization, 'overflow', 'Wrap', 'mode', adder_tree_impl});
	adder_tree_block.bindPort( adder_tree_inports, {sync_delay_out, add_tree_out} );	
	
	scaled_add_tree_out = xSignal;
	scale_block = xBlock(struct('source', 'Scale', 'name', ['scale_', num2str(k)]), ...
		{'scale_factor', -scale_factor}, ...
		{add_tree_out}, ...
		{scaled_add_tree_out});

	conv_block = xBlock(struct('source', 'Convert', 'name', ['convert_', num2str(k)]), ...
		struct('n_bits', BitWidthOut, ...
		'bin_pt', BitWidthOut-1, ...
		'quantization', 'Round  (unbiased: +/- Inf)', ...
		'overflow', 'Saturate', ...
		'latency', conv_latency, ...
		'pipeline', 'on'), ...
		{scaled_add_tree_out}, ...
		{adder_tree_outports{k}});

	if k == 1
		sync_delay1 = xBlock(struct('source', 'Delay', 'name', 'sync_delay1'), ...
			struct('latency', conv_latency), ...
			{sync_delay_out}, ...
			{sync_out});	
	end
end


if complex_inputs && biplex_inputs % combine into complex data type
	if strcmp(input_type, 'Complex')
		xBlock( struct('source', str2func('ri_to_c_init_xblock'), 'name', 'ri_to_c0'), struct(), ...
			{adder_tree_outports{1}, adder_tree_outports{2}}, {out1} );
	end	

	if strcmp(input_type, 'Complex')
		xBlock( struct('source', str2func('ri_to_c_init_xblock'), 'name', 'ri_to_c1'), struct(), ...
			{adder_tree_outports{3}, adder_tree_outports{4}}, {out2} );
	end	
elseif complex_inputs
	if strcmp(input_type, 'Complex')
		xBlock( struct('source', str2func('ri_to_c_init_xblock'), 'name', 'ri_to_c0'), struct(), ...
			{adder_tree_outports{1}, adder_tree_outports{2}}, {out} );
	end	
else 

% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% % macc_dsp48_ports
% if ~biplex_inputs
%     macc_dsp48_ports = {};
%     for k=1:TotalTaps
%         macc_dsp48_ports{2*k-1} = coeff_gen_outports{k+2};
%         macc_dsp48_ports{2*k} = delay_out_sigs{k};
%     end
%     if strcmp(mult_impl, 'DSP48e')
%         sync_delay_per = 2^(PFBSize-n_inputs) * (TotalTaps-1) + mult_latency + 1;
% 
%         macc_dsp48_outports = {};
%         adder_tree_inports = {sync_delay_out1};
%         for k=1:ceil(TotalTaps/2)
%             macc_dsp48_outports{k} = xSignal;
%             adder_tree_inports{k+1} = macc_dsp48_outports{k};
%         end
% 
%         % instantiate N-input MACC
%         macc_config.source = str2func('macc_dsp48e_init_xblock');
%         macc_config.name = 'macc_dsp48e';
%         macc_config.depend = {'macc_dsp48e_init_xblock.m'};
%         macc_dsp48e_2in_0_sub = xBlock(macc_config, {CoeffBitWidth, CoeffBitWidth-1, BitWidthIn, ...
%             BitWidthIn-1, 'on', CoeffBitWidth+BitWidthIn+1, CoeffBitWidth+BitWidthIn-2, 'Truncate', ...
%             'Wrap', 0, TotalTaps});
%         macc_dsp48e_2in_0_sub.bindPort( macc_dsp48_ports, macc_dsp48_outports);
% 
% 
%         % instantiate N-input adder tree
%         adder_tree_config.source = str2func('adder_tree_init_xblock');
%         adder_tree_config.name = 'adder_tree';
%         adder_tree_config.depend = {'adder_tree_init_xblock.m'};
%         adder_tree_block = xBlock( adder_tree_config, {TotalTaps/2, add_latency, quantization, 'Wrap', adder_tree_impl});
%         adder_tree_block.bindPort( adder_tree_inports, {sync_delay_out2, macc_dsp48e_2in_0_out1} );
% 
% 
%     elseif strcmp(mult_impl, 'Fabric')
%         sync_delay_per = 2^(PFBSize-n_inputs) * (TotalTaps-1) + mult_latency;
% 
% 
%         macc_dsp48_outports = {};
%         adder_tree_inports = {sync_delay_out1};
%         for k=1:TotalTaps
%             macc_dsp48_outports{k} = xSignal;
%             adder_tree_inports{k+1} = macc_dsp48_outports{k};
%         end
% 
%         % instantiate N-input MACC
%         macc_config.source = str2func('tap_multiply_fabric_init_xblock');
%         macc_config.name = 'tap_mult_fabric';
%         macc_dsp48e_2in_0_sub = xBlock(macc_config, {BitWidthIn, BitWidthIn-1, mult_latency, 'Truncate', ...
%             'Wrap', TotalTaps});
%         macc_dsp48e_2in_0_sub.bindPort( macc_dsp48_ports, macc_dsp48_outports);
% 
%         % instantiate N-input adder tree
%         adder_tree_config.source = str2func('adder_tree_init_xblock');
%         adder_tree_config.name = 'adder_tree';
%         adder_tree_config.depend = {'adder_tree_init_xblock.m'};
%         adder_tree_block = xBlock( adder_tree_config, {TotalTaps, add_latency, quantization, 'Wrap', adder_tree_impl});
%         adder_tree_block.bindPort( adder_tree_inports, {sync_delay_out2, macc_dsp48e_2in_0_out1} );
%     end
%     
%     scale_1_1_out1 = xSignal;
%     scale_1_1 = xBlock(struct('source', 'Scale', 'name', 'scale_1_1'), ...
%     struct('scale_factor', -scale_factor), ...
%     {macc_dsp48e_2in_0_out1}, ...
%     {scale_1_1_out1});
% 
%     convert_1_1 = xBlock(struct('source', 'Convert', 'name', 'convert_1_1'), ...
%         struct('n_bits', BitWidthOut, ...
%         'bin_pt', BitWidthOut-1, ...
%         'quantization', 'Round  (unbiased: +/- Inf)', ...
%         'overflow', 'Saturate', ...
%         'latency', 1, ...
%         'pipeline', 'on'), ...
%         {scale_1_1_out1}, ...
%         {out});
%        
% elseif biplex_inputs
%     macc_dsp48_ports1 = {};
%     macc_dsp48_ports2 = {};
%     
%     for k=1:TotalTaps
%         % split delay_out_sigs{k} into biplex components
%         pol1_data = xSignal;
%         pol2_data = xSignal;
%         xBlock( struct('source', 'gavrt_library/uncram', 'name', ['tap_split_', num2str(k)]), ...
%             struct('num_slice', 2, 'slice_width', BitWidthIn, 'bin_pt', BitWidthIn-1, 'arith_type', 1), ...
%             { delay_out_sigs{k} }, {pol1_data, pol2_data} );
%         
%         macc_dsp48_ports1{2*k-1} = coeff_gen_outports{k+2};
%         macc_dsp48_ports1{2*k} = pol1_data;
%         
%         macc_dsp48_ports2{2*k-1} = coeff_gen_outports{k+2};
%         macc_dsp48_ports2{2*k} = pol2_data;        
%     end
%     
%     add_tree1_sync_out = sync_delay_out2;
%     add_tree2_sync_out = xSignal;
%     add_tree1_dout = xSignal;
%     add_tree2_dout = xSignal;
%     
%     if strcmp(mult_impl, 'DSP48e')
%         sync_delay_per = 2^(PFBSize-n_inputs) * (TotalTaps-1) + mult_latency + 1;
% 
%         macc_dsp48_outports1 = {};
%         macc_dsp48_outports2 = {};
%         adder_tree_inports1 = {sync_delay_out1};
%         adder_tree_inports2 = {sync_delay_out1};
%         for k=1:ceil(TotalTaps/2)
%             macc_dsp48_outports1{k} = xSignal;
%             macc_dsp48_outports2{k} = xSignal;
%             adder_tree_inports1{k+1} = macc_dsp48_outports1{k};
%             adder_tree_inports2{k+1} = macc_dsp48_outports2{k};
%         end
% 
%         % instantiate N-input MACC for pol 1
%         macc_config.source = str2func('macc_dsp48e_init_xblock');
%         macc_config.name = 'macc_dsp48e1';
%         macc_config.depend = {'macc_dsp48e_init_xblock.m'};
%         macc_dsp48e_2in_0_sub = xBlock(macc_config, {CoeffBitWidth, CoeffBitWidth-1, BitWidthIn, ...
%             BitWidthIn-1, 'on', CoeffBitWidth+BitWidthIn+1, CoeffBitWidth+BitWidthIn-2, 'Truncate', ...
%             'Wrap', 0, TotalTaps});
%         macc_dsp48e_2in_0_sub.bindPort( macc_dsp48_ports1, macc_dsp48_outports1);
% 
% 
%         % instantiate N-input adder tree
%         adder_tree_config.source = str2func('adder_tree_init_xblock');
%         adder_tree_config.name = 'adder_tree1';
%         adder_tree_config.depend = {'adder_tree_init_xblock.m'};
%         adder_tree_block = xBlock( adder_tree_config, {TotalTaps/2, add_latency, quantization, 'Wrap', adder_tree_impl});
%         adder_tree_block.bindPort( adder_tree_inports1, {add_tree1_sync_out, add_tree1_dout} );
% 
%         % instantiate N-input MACC for pol 2
%         macc_config.source = str2func('macc_dsp48e_init_xblock');
%         macc_config.name = 'macc_dsp48e2';
%         macc_config.depend = {'macc_dsp48e_init_xblock.m'};
%         macc_dsp48e_2in_0_sub = xBlock(macc_config, {CoeffBitWidth, CoeffBitWidth-1, BitWidthIn, ...
%             BitWidthIn-1, 'on', CoeffBitWidth+BitWidthIn+1, CoeffBitWidth+BitWidthIn-2, 'Truncate', ...
%             'Wrap', 0, TotalTaps});
%         macc_dsp48e_2in_0_sub.bindPort( macc_dsp48_ports2, macc_dsp48_outports2);
% 
% 
%         % instantiate N-input adder tree
%         adder_tree_config.source = str2func('adder_tree_init_xblock');
%         adder_tree_config.name = 'adder_tree2';
%         adder_tree_config.depend = {'adder_tree_init_xblock.m'};
%         adder_tree_block = xBlock( adder_tree_config, {TotalTaps/2, add_latency, quantization, 'Wrap', adder_tree_impl});
%         adder_tree_block.bindPort( adder_tree_inports2, {add_tree2_sync_out, add_tree2_dout} );        
%         
% 
%     elseif strcmp(mult_impl, 'Fabric')
%         sync_delay_per = 2^(PFBSize-n_inputs) * (TotalTaps-1) + mult_latency;
% 
%         
%         macc_dsp48_outports1 = {};
%         macc_dsp48_outports2 = {};
%         adder_tree_inports1 = {sync_delay_out1};
%         adder_tree_inports2 = {sync_delay_out1};
%         for k=1:TotalTaps
%             macc_dsp48_outports1{k} = xSignal;
%             macc_dsp48_outports2{k} = xSignal;
%             adder_tree_inports1{k+1} = macc_dsp48_outports1{k};
%             adder_tree_inports2{k+1} = macc_dsp48_outports2{k};
%         end
% 
%         % instantiate N-input MACC for pol1
%         macc_config.source = str2func('tap_multiply_fabric_init_xblock');
%         macc_config.name = 'tap_mult_fabric1';
%         macc_dsp48e_2in_0_sub = xBlock(macc_config, {BitWidthIn, BitWidthIn-1, mult_latency, 'Truncate', ...
%             'Wrap', TotalTaps});
%         macc_dsp48e_2in_0_sub.bindPort( macc_dsp48_ports1, macc_dsp48_outports1);
% 
%         % instantiate N-input adder tree for pol1
%         adder_tree_config.source = str2func('adder_tree_init_xblock');
%         adder_tree_config.name = 'adder_tree1';
%         adder_tree_config.depend = {'adder_tree_init_xblock.m'};
%         adder_tree_block = xBlock( adder_tree_config, {TotalTaps, add_latency, quantization, 'Wrap', adder_tree_impl});
%         adder_tree_block.bindPort( adder_tree_inports1, {add_tree1_sync_out, add_tree1_dout} );
%         
%         % instantiate N-input MACC for pol2
%         macc_config.source = str2func('tap_multiply_fabric_init_xblock');
%         macc_config.name = 'tap_mult_fabric2';
%         macc_dsp48e_2in_0_sub = xBlock(macc_config, {BitWidthIn, BitWidthIn-1, mult_latency, 'Truncate', ...
%             'Wrap', TotalTaps});
%         macc_dsp48e_2in_0_sub.bindPort( macc_dsp48_ports2, macc_dsp48_outports2);
% 
%         % instantiate N-input adder tree for pol2
%         adder_tree_config.source = str2func('adder_tree_init_xblock');
%         adder_tree_config.name = 'adder_tree2';
%         adder_tree_config.depend = {'adder_tree_init_xblock.m'};
%         adder_tree_block = xBlock( adder_tree_config, {TotalTaps, add_latency, quantization, 'Wrap', adder_tree_impl});
%         adder_tree_block.bindPort( adder_tree_inports2, {add_tree2_sync_out, add_tree2_dout} );        
%     end
%     
%     scale_1_1_out1 = xSignal;
%     scale_1_2_out1 = xSignal;
%     scale_1_1 = xBlock(struct('source', 'Scale', 'name', 'scale_1_1'), ...
%     struct('scale_factor', -scale_factor), ...
%     {add_tree1_dout}, ...
%     {scale_1_1_out1});
% 
%     convert_1_1 = xBlock(struct('source', 'Convert', 'name', 'convert_1_1'), ...
%         struct('n_bits', BitWidthOut, ...
%         'bin_pt', BitWidthOut-1, ...
%         'quantization', 'Round  (unbiased: +/- Inf)', ...
%         'overflow', 'Saturate', ...
%         'latency', 1, ...
%         'pipeline', 'on'), ...
%         {scale_1_1_out1}, ...
%         {out1});    
% 
%         scale_1_2 = xBlock(struct('source', 'Scale', 'name', 'scale_1_2'), ...
%     struct('scale_factor', -scale_factor), ...
%     {add_tree2_dout}, ...
%     {scale_1_2_out1});
% 
%     convert_1_2 = xBlock(struct('source', 'Convert', 'name', 'convert_1_2'), ...
%         struct('n_bits', BitWidthOut, ...
%         'bin_pt', BitWidthOut-1, ...
%         'quantization', 'Round  (unbiased: +/- Inf)', ...
%         'overflow', 'Saturate', ...
%         'latency', 1, ...
%         'pipeline', 'on'), ...
%         {scale_1_2_out1}, ...
%         {out2});   
%     if strcmp(input_type, 'Complex')
%         xBlock( struct('source', 'casper_library_misc/ri_to_c', 'name', 'ri_to_c'), struct(), ...
%             {out1, out2}, {out} );
%     end
%     
% end
% 

end
% 
% 
% function draw_fir_subrows(mult_impl, TotalTaps, data_inports, num_subrows)
% 
% 	
%     if strcmp(mult_impl, 'DSP48e')
%         macc_dsp48_outports = {};
%         adder_tree_inports = {sync_delay_out1};
%         for k=1:ceil(TotalTaps/2)
%             macc_dsp48_outports{k} = xSignal;
%             adder_tree_inports{k+1} = macc_dsp48_outports{k};
%         end
% 
%         % instantiate N-input MACC
%         macc_config.source = str2func('macc_dsp48e_init_xblock');
%         macc_config.name = 'macc_dsp48e';
%         macc_config.depend = {'macc_dsp48e_init_xblock.m'};
%         macc_dsp48e_2in_0_sub = xBlock(macc_config, {CoeffBitWidth, CoeffBitWidth-1, BitWidthIn, ...
%             BitWidthIn-1, 'on', CoeffBitWidth+BitWidthIn+1, CoeffBitWidth+BitWidthIn-2, 'Truncate', ...
%             'Wrap', 0, TotalTaps});
%         macc_dsp48e_2in_0_sub.bindPort( macc_dsp48_ports, macc_dsp48_outports);
% 
% 
%         % instantiate N-input adder tree
%         adder_tree_config.source = str2func('adder_tree_init_xblock');
%         adder_tree_config.name = 'adder_tree';
%         adder_tree_config.depend = {'adder_tree_init_xblock.m'};
%         adder_tree_block = xBlock( adder_tree_config, {TotalTaps/2, add_latency, quantization, 'Wrap', adder_tree_impl});
%         adder_tree_block.bindPort( adder_tree_inports, {sync_delay_out2, macc_dsp48e_2in_0_out1} );
% 
%     elseif strcmp(mult_impl, 'Fabric')
%         macc_dsp48_outports = {};
%         adder_tree_inports = {sync_delay_out1};
%         for k=1:TotalTaps
%             macc_dsp48_outports{k} = xSignal;
%             adder_tree_inports{k+1} = macc_dsp48_outports{k};
%         end
% 
%         % instantiate N-input MACC
%         macc_config.source = str2func('tap_multiply_fabric_init_xblock');
%         macc_config.name = 'tap_mult_fabric';
%         macc_dsp48e_2in_0_sub = xBlock(macc_config, {BitWidthIn, BitWidthIn-1, mult_latency, 'Truncate', ...
%             'Wrap', TotalTaps});
%         macc_dsp48e_2in_0_sub.bindPort( macc_dsp48_ports, macc_dsp48_outports);
% 
%         % instantiate N-input adder tree
%         adder_tree_config.source = str2func('adder_tree_init_xblock');
%         adder_tree_config.name = 'adder_tree';
%         adder_tree_config.depend = {'adder_tree_init_xblock.m'};
%         adder_tree_block = xBlock( adder_tree_config, {TotalTaps, add_latency, quantization, 'Wrap', adder_tree_impl});
%         adder_tree_block.bindPort( adder_tree_inports, {sync_delay_out2, macc_dsp48e_2in_0_out1} );
%     end
%     
% 
% end


