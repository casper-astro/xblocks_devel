%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011                Hong Chen                               %
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
function delay_bram_init_xblock(DelayLen, bram_latency, use_dsp48)


if (DelayLen <= bram_latency)
	error('delay value must be greater than BRAM Latency');
end
BitWidth = max(ceil(log2(DelayLen)), 2);
if strcmp(use_dsp48, 'on'),
    use_dsp48_im='DSP48';
else,
    use_dsp48_im='Fabric';
end

%% inports
xlsub2_In1 = xInport('In1');

%% outports
xlsub2_Out1 = xOutport('Out1');

%% diagram

% block: delay_7/delay_bram/Constant2
xlsub2_Constant2_out1 = xSignal;
xlsub2_Constant2 = xBlock(struct('source', 'Constant', 'name', 'Constant2'), ...
                          struct('arith_type', 'Boolean', ...
                                 'n_bits', 1, ...
                                 'bin_pt', 0, ...
                                 'explicit_period', 'on'), ...
                          {}, ...
                          {xlsub2_Constant2_out1});

% block: delay_7/delay_bram/Counter
xlsub2_Counter_out1 = xSignal;
xlsub2_Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
                        struct('cnt_type', 'Count Limited', ...
                               'cnt_to', DelayLen - bram_latency - 1, ...
                               'n_bits', BitWidth, ...
                               'use_rpm', use_dsp48, ...
                               'implementation', use_dsp48_im), ...
                        {}, ...
                        {xlsub2_Counter_out1});

% block: delay_7/delay_bram/Single Port RAM
xlsub2_Single_Port_RAM = xBlock(struct('source', 'Single Port RAM', 'name', 'Single Port RAM'), ...
                                struct('depth', 2^BitWidth, ...
                                       'initVector', 0, ...
                                       'write_mode', 'Read Before Write', ...
                                       'latency', bram_latency, ...
                                       'use_rpm', 'off'), ...
                                {xlsub2_Counter_out1, xlsub2_In1, xlsub2_Constant2_out1}, ...
                                {xlsub2_Out1});



end

