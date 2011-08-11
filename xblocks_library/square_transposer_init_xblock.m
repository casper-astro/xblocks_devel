%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011  Hong Chen                                             %
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
function square_transposer_init_xblock(blk, n_inputs)
% depends = {'barrel_switcher_init_xblock'}


if n_inputs < 1,
    error('Number of inputs must be 2^1 or greater.');
    return;
end

%% inports
xlsub2_sync = xInport('sync');
xlsub2_In = cell(1,2^n_inputs);
for i = 1:2^n_inputs,
    xlsub2_In{i} = xInport(['In',num2str(i)]);
end


%% outports
xlsub2_sync_out = xOutport('sync_out');
xlsub2_Out = cell(1,2^n_inputs);
for i = 1:2^n_inputs,
    xlsub2_Out{i} = xOutport(['Out',num2str(i)]);
end

%% diagram

% block: Delayf & Delayb
Delayf = cell(1,2^n_inputs);
Delayb = cell(1,2^n_inputs);
xlsub2_barrel_switcher_In = cell(1,2^n_inputs);
xlsub2_barrel_switcher_Out = cell(1,2^n_inputs);
for i=1:2^n_inputs,
    if i == 1,
        dport = 3;
    else
        dport = (2^n_inputs - i + 2) + 2;
    end
    xlsub2_barrel_switcher_In{dport-2} = xSignal(['barrel_switcher_In',num2str(dport-2)]);
    xlsub2_barrel_switcher_Out{i} = xSignal(['barrel_switcher_Out',num2str(i)]);
    Delayf{i} = xBlock(struct('source', 'Delay', 'name', ['Delayf',num2str(i)]), ...
                        {'latency', i-1}, ...
                        {xlsub2_In{i}}, ...
                        {xlsub2_barrel_switcher_In{dport-2}});
    Delayb{i} = xBlock(struct('source', 'Delay', 'name', ['Delayb',num2str(i)]), ...
                        {'latency', 2^n_inputs-i}, ...
                        {xlsub2_barrel_switcher_Out{i}}, ...
                        {xlsub2_Out{i}});
end

% block: untitled/square_transposer/counter
xlsub2_counter_out1 = xSignal;
xlsub2_counter = xBlock(struct('source', 'Counter', 'name', 'counter'), ...
                        struct('operation', 'Down', ...
                               'n_bits', n_inputs, ...
                               'rst', 'on', ...
                               'explicit_period', 'off', ...
                               'use_rpm', 'on'), ...
                        {xlsub2_sync}, ...
                        {xlsub2_counter_out1});

% block: untitled/square_transposer/delay0
xlsub2_barrel_switcher_out1 = xSignal;
xlsub2_delay0 = xBlock(struct('source', 'Delay', 'name', 'delay0'), ...
                       [], ...
                       {xlsub2_barrel_switcher_out1}, ...
                       {xlsub2_sync_out});

% block: untitled/square_transposer/barrel_switcher
xlsub2_barrel_switcher_sub = xBlock(struct('source', str2func('barrel_switcher_init_xblock'), 'name', 'barrel_switcher'), ...
                                {[blk, '/barrel_switcher'], n_inputs}, ...
                                [{xlsub2_counter_out1}, {xlsub2_sync}, xlsub2_barrel_switcher_In], ...
                                [{xlsub2_barrel_switcher_out1}, xlsub2_barrel_switcher_Out]);


if ~isempty(blk) && ~strcmp(blk(1), '/')
    clean_blocks(blk);

    fmtstr = sprintf('n_inputs=%d', n_inputs);
    set_param(blk, 'AttributesFormatString', fmtstr);
end

end
