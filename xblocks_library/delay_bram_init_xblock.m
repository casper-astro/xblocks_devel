%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Hong Chen                                              %
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
function delay_bram_init_xblock(varargin)
defaults = { ...
    'n_inputs', 1, ...
    'latency', 7, ...
    'bram_latency', 4, ...
    'arch', 'V5', ...
    'count_using_dsp48', 0};

n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
latency = get_var('latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
arch = get_var('arch', 'defaults', defaults, varargin{:});
count_using_dsp48 = get_var('count_using_dsp48', 'defaults', defaults, varargin{:});

if (latency <= bram_latency)
	errordlg('delay value must be greater than BRAM Latency');
end

bit_width = max(ceil(log2(latency)), 2);
if strcmp(count_using_dsp48, 'on'),
    count_using_dsp48_im='DSP48';
else
    count_using_dsp48_im='Fabric';
end

use_dual_port_ram = strcmp(arch, 'V5') && (bit_width <= 9);

%% inports
din = xblock_new_inputs('din', n_inputs, 1);

%% outports
dout = xblock_new_outputs('dout', n_inputs, 1);

%% diagram

% block: delay_7/delay_bram/Constant2
we = xSignal;
Constant2 = xBlock(struct('source', 'Constant', 'name', 'Constant2'), ...
                          struct('arith_type', 'Boolean', ...
                                 'n_bits', 1, 'bin_pt', 0, 'explicit_period', 'on'), ...
                          {}, {we});

% block: delay_7/delay_bram/Counter
addr = xSignal;
if latency > (bram_latency + 1)
    Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
                            struct('cnt_type', 'Count Limited', ...
                                   'cnt_to', latency - bram_latency - 1, ...
                                   'n_bits', bit_width, ...
                                   'use_rpm', count_using_dsp48, ...
                                   'implementation', count_using_dsp48_im), ...
                            {}, ...
                            {addr});
else
    Constant1 = xBlock(struct('source', 'Constant', 'name', 'Constant1'), ...
                          struct('const',0, ...
                                 'n_bits', bit_width, ...
                                 'bin_pt', 0, ...
                                 'explicit_period', 'on'), ...
                          {}, ...
                          {addr});
end

if use_dual_port_ram
    n_dual_port_ram = floor(n_inputs/2);
    n_single_port_ram = mod(n_inputs,2);
else
    n_dual_port_ram = 0;
    n_single_port_ram = n_inputs;
end

% dpr_inputs = din{ [1:n_dual_port_ram*2], 1};
% spr_inputs = din{ [n_dual_port_ram*2+1:end], 1};


    for k = 1:n_inputs
        bram_config.source = 'Single Port RAM';
        bram_config.name = ['bram', num2str(k)];
        bram_params = struct('depth', 2^bit_width, 'initVector', 0, 'write_mode', 'Read Before Write', ...
            'latency', bram_latency, 'use_rpm', 'off');
        single_port_bram = xBlock(bram_config, bram_params, {addr, din{k,1}, we}, {dout{k,1}});
    end                            


end

