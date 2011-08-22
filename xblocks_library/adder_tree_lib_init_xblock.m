% Create a tree of adders.
%
% adder_tree_init(blk, varargin)
%
% blk = The block to be configured.
% varargin = {'varname', 'value', ...} pairs
%
% Valid varnames for this block are:
% n_inputs = Number of inputs
% latency = Latency per adder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://seti.ssl.berkeley.edu/casper/                                      %
%   Copyright (C) 2006 David MacMahon, Aaron Parsons                          %
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

function adder_tree_lib_init_xblock(blk,varargin)

defaults = {'n_inputs', 3, 'latency', 1, 'first_stage_hdl', 'off', 'adder_imp', 'Fabric'};

n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
latency = get_var('latency', 'defaults', defaults, varargin{:});
first_stage_hdl = get_var('first_stage_hdl', 'defaults', defaults, varargin{:});
adder_imp = get_var('adder_imp', 'defaults', defaults, varargin{:});

hw_selection = adder_imp;

if strcmp(adder_imp,'on'), 
  first_stage_hdl = 'on'; 
end
if strcmp(adder_imp, 'Behavioral'),
  behavioral = 'on';
  hw_selection = 'Fabric';
else
  behavioral = 'off';
end

stages = ceil(log2(n_inputs));



% add In/Out ports
sync = xInport('sync');
sync_out = xOutport('sync_out');

din = cell(1,n_inputs);
for i=1:n_inputs,
    din{i} = xInport(['din',num2str(i)]);
end
dout = xOutport('dout');

% Take care of sync
sync_delay = xBlock(struct('source', 'xbsIndex_r4/Delay','name','sync_delay'), ...
                    {'latency', stages*latency, ...
                     'reg_retiming', 'on'}, ...
                     {sync}, ...
                     {sync_out});




% Take care of adder tree

% If nothing to add, connect in to out
if stages==0
    dout.bind(din{1});
else
    % Make adder tree
    cur_n = n_inputs;
    stage = 0;
    blk_cnt = 0;
    blks = {};
    adder_outs = cell(1,stages);
    while cur_n > 1,
        n_adds = floor(cur_n / 2);
        n_dlys = mod(cur_n, 2);
        cur_n = n_adds + n_dlys;
        prev_blks = blks;
        blks = {};
        stage = stage + 1;
        adder_outs{stage} = cell(1,cur_n);
        for j=1:cur_n,
            blk_cnt = blk_cnt + 1;
            if j <= n_adds,
                addr = ['addr',num2str(blk_cnt)];
                blks{j} = addr;
                adder_outs{stage}{j}=xSignal(['adder_outs',num2str(stage),'_',num2str(j)]);
                if stage == 1
                    xBlock(struct('source', 'xbsIndex_r4/AddSub', 'name', addr), ...
                            {'latency', latency, ...
                              'use_behavioral_HDL', first_stage_hdl, 'hw_selection', hw_selection, ...
                             'pipelined', 'on', 'use_rpm', 'on'}, ...
                             {din{j*2-1}, din{j*2}}, ...
                             {adder_outs{stage}{j}});
                else
                           xBlock(struct('source', 'xbsIndex_r4/AddSub', 'name', addr), ...
                            {'latency', latency, ...
                              'use_behavioral_HDL', behavioral, 'hw_selection', hw_selection, ...
                             'pipelined', 'on', 'use_rpm', 'on'}, ...
                             {adder_outs{stage-1}{j*2-1}, adder_outs{stage-1}{j*2}}, ...
                             {adder_outs{stage}{j}});
                end
            else
                dly = ['dly',num2str(blk_cnt)];
                blks{j} = dly;
                adder_outs{stage}{j}=xSignal(['adder_outs',num2str(stage),'_',num2str(j)]);
                if stage == 1
                    xBlock(struct('source', 'xbsIndex_r4/Delay','name', dly), ...
                            {'latency', latency, ...
                                'reg_retiming', 'on'}, ...
                                {din{j*2-1}}, ...
                                {adder_outs{stage}{j}});
                else
                    xBlock(struct('source', 'xbsIndex_r4/Delay','name', dly), ...
                            {'latency', latency, ...
                                'reg_retiming', 'on'}, ...
                                {adder_outs{stage-1}{j*2-1}}, ...
                                {adder_outs{stage}{j}});
                end
            end
        end
    end
    dout.bind(adder_outs{stages}{1});
end

if ~isempty(blk) && ~strcmp(blk(1), '/')
    % When finished drawing blocks and lines, remove all unused blocks.
    clean_blocks(blk);

    % Set attribute format string (block annotation)
    annotation=sprintf('latency %d',stages*latency);
    set_param(blk,'AttributesFormatString',annotation);
end

end
