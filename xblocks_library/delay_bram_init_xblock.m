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
function delay_bram_init_xblock(blk, DelayLen, bram_latency, use_dsp48)


if (DelayLen <= bram_latency)
	errordlg('delay value must be greater than BRAM Latency');
end


BitWidth = max(ceil(log2(DelayLen)), 2);
if strcmp(use_dsp48, 'on'),
    use_dsp48_im='DSP48';
else
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
if DelayLen > (bram_latency + 1)
    xlsub2_Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
                            struct('cnt_type', 'Count Limited', ...
                                   'cnt_to', DelayLen - bram_latency - 1, ...
                                   'n_bits', BitWidth, ...
                                   'use_rpm', use_dsp48, ...
                                   'implementation', use_dsp48_im), ...
                            {}, ...
                            {xlsub2_Counter_out1});
else
    xlsub2_Constant1 = xBlock(struct('source', 'Constant', 'name', 'Constant1'), ...
                          struct('const',0, ...
                                 'n_bits', BitWidth, ...
                                 'bin_pt', 0, ...
                                 'explicit_period', 'on'), ...
                          {}, ...
                          {xlsub2_Counter_out1});
end

% block: delay_7/delay_bram/Single Port RAM
xlsub2_Single_Port_RAM = xBlock(struct('source', 'Single Port RAM', 'name', 'Single Port RAM'), ...
                                struct('depth', 2^BitWidth, ...
                                       'initVector', 0, ...
                                       'write_mode', 'Read Before Write', ...
                                       'latency', bram_latency, ...
                                       'use_rpm', 'off'), ...
                                {xlsub2_Counter_out1, xlsub2_In1, xlsub2_Constant2_out1}, ...
                                {xlsub2_Out1});
                            
if ~isempty(blk) && ~strcmp(blk(1), '/')
    annotation_fmt = 'Delay Length=%d\nbram_latency=%d\n%s';
    if strcmp(use_dsp48,'on')
        ss='use_dsp48';
    else
        ss = '';
    end
    annotation = sprintf(annotation_fmt, ...
        DelayLen, bram_latency, ss);
    set_param(blk, 'AttributesFormatString', annotation);
    clean_blocks(blk);
end


end

