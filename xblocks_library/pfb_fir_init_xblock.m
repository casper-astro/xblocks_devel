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
%% TODO
function pfb_fir_init_xblock(blk, varargin)    

defaults = {'PFBSize', 5, 'TotalTaps', 2, ...
    'WindowType', 'hamming', 'n_inputs', 1, 'MakeBiplex', 0, ...
    'BitWidthIn', 8, 'BitWidthOut', 18, 'CoeffBitWidth', 18, ...
    'CoeffDistMem', 0, 'add_latency', 1, 'mult_latency', 2, ...
    'bram_latency', 2, ...
    'quantization', 'Round  (unbiased: +/- Inf)', ...
    'fwidth', 1, 'specify_mult', 'off', 'mult_spec', [2 2], ...
    'adder_tree_impl', 'Behavioral', 'mult_impl', 'Fabric', ...
	'input_latency', 0, 'input_type', 'Complex', 'biplex_inputs', 0};    
    
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
conv_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
fwidth = get_var('fwidth', 'defaults', defaults, varargin{:});

adder_tree_impl = get_var('adder_tree_impl', 'defaults', defaults, varargin{:});
mult_impl = get_var('mult_impl', 'defaults', defaults, varargin{:});
input_latency = get_var('input_latency', 'defaults', defaults, varargin{:});
input_type = get_var('input_type', 'defaults', defaults, varargin{:});

%% inports & outports

sync_in = xInport('sync');
sync_out = xOutport('sync_out');

if MakeBiplex
	pols = 2;
else
    pols = 1;
end

pol1_in = cell(pols,2^n_inputs);
pol1_out = cell(pols,2^n_inputs);
sync_out_conn = cell(pols, 2^n_inputs);
for p = 1:pols,
    for k=1:2^n_inputs
        % declare input port
        pol1_in{p,k} = xInport(['pol', num2str(p), '_in', num2str(k)]);
        
        % declare output port
        pol1_out{p,k} = xOutport(['pol', num2str(p), '_out', num2str(k)]);
        
        % config for pfb_row
        pfb_row_k_config.source = str2func('pfb_row_init_xblock');
        pfb_row_k_config.name   = ['pfb_row_', num2str(p), num2str(k)];
        
        sync_out_conn{p,k} = [];
        if k == 1 && p == 1,
            sync_out_conn{p,k} = sync_out;
        end
        
        pfb_row_block = xBlock(pfb_row_k_config, ...
                {[blk,'/',pfb_row_k_config.name], ...
                'nput', k-1, 'PFBSize', PFBSize, 'CoeffBitWidth', CoeffBitWidth, 'TotalTaps', TotalTaps, ...
                'BitWidthIn', BitWidthIn, 'BitWidthOut', BitWidthOut, 'CoeffDistMem', CoeffDistMem, ...
                'WindowType', WindowType, 'add_latency', add_latency, 'biplex_inputs', 0, ...  % no biplex for now
                'mult_latency', mult_latency, 'bram_latency', bram_latency, 'n_inputs', n_inputs, ...
                'fwidth', fwidth, 'conv_latency', conv_latency, 'adder_tree_impl', adder_tree_impl, ...
                'quantization', quantization, 'mult_impl', mult_impl, ...
                'input_latency', input_latency, 'input_type', input_type}, ...
                {pol1_in{p,k}, sync_in},... % inputs
                {sync_out_conn{p,k}, pol1_out{p,k}});    % outputs
        
    end
end

if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);

    fmtstr = sprintf('taps=%d, add_latency=%d', TotalTaps, add_latency);
    set_param(blk, 'AttributesFormatString', fmtstr);
end
end

