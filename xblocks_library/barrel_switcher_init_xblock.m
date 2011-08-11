%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011  Hong Chen, Terry Filiba, Aaron Parsons                %
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

function barrel_switcher_init_xblock(blk, n_inputs)



%% inports
xlsub5_sel = xInport('sel');
xlsub5_sync_in = xInport('sync_in');
xlsub5_In = cell(1,2^n_inputs);
for i=1:2^n_inputs,
    xlsub5_In{i} = xInport(['In',num2str(i)]);
end


%% outports
xlsub5_sync_out = xOutport('sync_out');
xlsub5_Out = cell(1,2^n_inputs);
for i=1:2^n_inputs,
    xlsub5_Out{i} = xOutport(['Out',num2str(i)]);
end


%% diagram


% block: untitled/fft/fft_biplex0/biplex_cplx_unscrambler/barrel_switcher/Delay_sync
xlsub5_Delay_sync = xBlock(struct('source', 'Delay', 'name', 'Delay_sync'), ...
                           [], ...
                           {xlsub5_sync_in}, ...
                           {xlsub5_sync_out});

                       



% Delays
if n_inputs > 1,
    xlsub5_Delay = cell(1,n_inputs-1);
    xlsub5_Delay_Inport = cell(1,n_inputs-1);
    xlsub5_Delay_Outport = cell(1,n_inputs-1);
    xlsub5_Delay_Inport{1} = xlsub5_sel;
    for i=1:(n_inputs-1),
        xlsub5_Delay_Outport{i} = xSignal(['Delay',num2str(i),'_out']);
    end
    for i=2:(n_inputs-1),
        xlsub5_Delay_Inport{i} = xlsub5_Delay_Outport{i-1};
    end
    for i=1:(n_inputs-1),
        xlsub5_Delay{i}= xBlock(struct('source', 'Delay', 'name', ['Delay',num2str(i)]), ...
                               [], ...
                               {xlsub5_Delay_Inport{i}}, ...
                               {xlsub5_Delay_Outport{i}});
    end
end


% Slices
xlsub5_Slice = cell(1,n_inputs);
xlsub5_Slice_Inport = cell(1,n_inputs);
xlsub5_Slice_Outport = cell(1,n_inputs);
xlsub5_Slice_Inport{1}=xlsub5_sel;
for i=2:n_inputs,
    xlsub5_Slice_Inport{i} = xlsub5_Delay_Outport{i-1};  % from Delay outports (Delay to Next SLice)
end
for i=1:n_inputs,
    xlsub5_Slice_Outport{i} = xSignal(['Slice',num2str(i),'_out']);
end
for i=1:n_inputs,
    xlsub5_Slice{i} = xBlock(struct('source', 'Slice', 'name', ['Slice',num2str(i)]), ...
                       struct('bit1', -(i-1)), ...
                       {xlsub5_Slice_Inport{i}}, ...
                       {xlsub5_Slice_Outport{i}});
end


% Muxes                       
xlsub5_Mux=cell(2^n_inputs,n_inputs);
xlsub5_Mux_Inport = cell(3*2^n_inputs,n_inputs);
xlsub5_Mux_Outport = cell(2^n_inputs,n_inputs);
for j=1:n_inputs,   % Slice -> Mux_port1, taking care of the top Inport for every Muxes
    for i=1:2^n_inputs,
        xlsub5_Mux_Inport{3*(i-1)+1,j} = xlsub5_Slice_Outport{j};
    end
end
for i=1:2^n_inputs,  % generate all outport signals except for the last column of outports
    for j=1:n_inputs-1,
        xlsub5_Mux_Outport{i,j} = xSignal(['Mux_',num2str(i),'_',num2str(j),'_out']);
    end
end
for i=1:2^n_inputs,  % taking care of the outports of the last column of Muxes
    xlsub5_Mux_Outport{i,n_inputs} = xlsub5_Out{i};
end

for i=1:2^n_inputs,  % taking care of the middle Inport of the first column of Muxes
    xlsub5_Mux_Inport{3*(i-1)+2,1} = xlsub5_In{i};
end
for j=2:n_inputs,   % taking care of the the middle Inport of the other Muxes column by column
    for i=1:2^n_inputs,
        xlsub5_Mux_Inport{3*(i-1)+2,j} = xlsub5_Mux_Outport{i,j-1};
    end
end

for i=1:2^n_inputs,  % taking care of the bottom Inport of the first column of Muxes
    if i > 2^n_inputs / 2,
        xlsub5_Mux_Inport{3*(i-2^n_inputs/2),1} = xlsub5_In{i};
    else
        xlsub5_Mux_Inport{3*(i-2^n_inputs/2 + 2^n_inputs),1} = xlsub5_In{i};
    end
end

for i=1:2^n_inputs, % taking care of the bottom Inport of each Mux except for the first column
    for j=1:(n_inputs-1),
        
        if i > 2^n_inputs / (2^(j+1))
            xlsub5_Mux_Inport{3*(i-2^n_inputs/(2^(j+1))),j+1} = xlsub5_Mux_Outport{i,j};
        else
            xlsub5_Mux_Inport{3*(i-2^n_inputs/(2^(j+1)) + 2^n_inputs),j+1} = xlsub5_Mux_Outport{i,j};
        end
    end
end



for i=1:2^n_inputs,  % drawing the Muxes blocks
    for j=1:n_inputs,
        xlsub5_Mux{i,j} = xBlock(struct('source', 'Mux', 'name', ['Mux',num2str(10*i+j)]), ...
                      struct('latency', 1, ...
                             'arith_type', 'Signed  (2''s comp)', ...
                             'n_bits', 8, ...
                             'bin_pt', 2), ...
                      {xlsub5_Mux_Inport{3*(i-1)+1,j},xlsub5_Mux_Inport{3*(i-1)+2,j},xlsub5_Mux_Inport{3*i,j}}, ...
                      {xlsub5_Mux_Outport{i,j}});
    end
end


% % block: untitled/fft/fft_biplex0/biplex_cplx_unscrambler/barrel_switcher/Mux11
% xlsub5_Slice1_out1 = xSignal;
% xlsub5_Mux11 = xBlock(struct('source', 'Mux', 'name', 'Mux11'), ...
%                       struct('latency', 1, ...
%                              'arith_type', 'Signed  (2''s comp)', ...
%                              'n_bits', 8, ...
%                              'bin_pt', 2), ...
%                       {xlsub5_Slice1_out1, xlsub5_In1, xlsub5_In2}, ...
%                       {xlsub5_Out1});
% 
% % block: untitled/fft/fft_biplex0/biplex_cplx_unscrambler/barrel_switcher/Mux21
% xlsub5_Mux21 = xBlock(struct('source', 'Mux', 'name', 'Mux21'), ...
%                       struct('latency', 1, ...
%                              'arith_type', 'Signed  (2''s comp)', ...
%                              'n_bits', 8, ...
%                              'bin_pt', 2), ...
%                       {xlsub5_Slice1_out1, xlsub5_In2, xlsub5_In1}, ...
%                       {xlsub5_Out2});
% 
% % block: untitled/fft/fft_biplex0/biplex_cplx_unscrambler/barrel_switcher/Slice1
% xlsub5_Slice1 = xBlock(struct('source', 'Slice', 'name', 'Slice1'), ...
%                        struct('bit1', -0), ...
%                        {xlsub5_sel}, ...
%                        {xlsub5_Slice1_out1});

if ~isempty(blk) && ~strcmp(blk(1), '/')
    clean_blocks(blk);
    fmtstr = sprintf('n_inputs=%d', n_inputs);
    set_param(blk, 'AttributesFormatString', fmtstr);
end
end

