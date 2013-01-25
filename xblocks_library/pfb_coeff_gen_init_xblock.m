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
function pfb_coeff_gen_init_xblock(blk, PFBSize, CoeffBitWidth, TotalTaps, CoeffDistMem, WindowType, bram_latency, n_inputs, nput, fwidth, oversample_factor, oversample_index)

%% inports
xlsub3_din = xInport('din');
xlsub3_sync = xInport('sync');

%% outports
xlsub3_dout = xOutport('dout');
xlsub3_sync_out = xOutport('sync_out');

%% diagram

% block: dsp48e_pfb_test2/pfb_row/pfb_coeff_gen_new/Counter
xlsub3_Counter_out1 = xSignal;
xlsub3_Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
                        struct('n_bits', PFBSize-n_inputs, ...
                               'rst', 'on', ...
                               'use_rpm', 'on'), ...
                        {xlsub3_sync}, ...
                        {xlsub3_Counter_out1});

% block: dsp48e_pfb_test2/pfb_row/pfb_coeff_gen_new/Delay
xlsub3_Delay = xBlock(struct('source', 'Delay', 'name', 'Delay'), ...
                      struct('latency', bram_latency+1), ...
                      {xlsub3_sync}, ...
                      {xlsub3_sync_out});

% block: dsp48e_pfb_test2/pfb_row/pfb_coeff_gen_new/Delay1
xlsub3_Delay1 = xBlock(struct('source', 'Delay', 'name', 'Delay1'), ...
                       struct('latency', bram_latency+1), ...
                       {xlsub3_din}, ...
                       {xlsub3_dout});

% block: dsp48e_pfb_test2/pfb_row/pfb_coeff_gen_new/ROM1
ROM_blocks = [];
if CoeffDistMem
    distributed_mem ='Distributed memory';
else
    distributed_mem = 'Block RAM';
end
for k=TotalTaps:-1:1,
    xlsub3_ROM1_out1 = xSignal;
    xlsub3_ROM1 = xBlock(struct('source', 'ROM', 'name', ['ROM', num2str(k)]), ...
                         struct('depth', 2^(PFBSize-n_inputs), ...
                                'initVector', pfb_coeff_gen_calc_xblock(PFBSize,TotalTaps,WindowType,n_inputs,nput,fwidth, k,oversample_factor,oversample_index), ...
                                'latency', bram_latency, ...
                                'n_bits', CoeffBitWidth, ...
                                'bin_pt', CoeffBitWidth-1, ...
                                'distributed_mem',distributed_mem), ...
                         {xlsub3_Counter_out1}, ...
                         {xlsub3_ROM1_out1});
    ROM_blocks = [ROM_blocks, xlsub3_ROM1];

    coeff_outport = xOutport(['coeffs', num2str(TotalTaps-k+1)]);
    xlsub3_Register = xBlock(struct('source', 'Register', 'name', ['Register', num2str(k)]), ...
                             [], ...
                             {xlsub3_ROM1_out1}, ...
                             {coeff_outport });
    
end

if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    fmtstr = sprintf('PFBSize=%d, n_inputs=%d, taps=%d', PFBSize, n_inputs, TotalTaps);
    set_param(blk, 'AttributesFormatString', fmtstr);
end

end

