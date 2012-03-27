%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011    Hong Chen  (based on CASPER library dsp_scope block)%
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
function parallelizer_init_xblock(blk, varargin)

defaults = {...
    'n_outputs',8, ...
    'sample_period',1, ...
    'xilinx', 1};

n_outputs = get_var('n_outputs', 'defaults', defaults, varargin{:});
sample_period = get_var('sample_period', 'defaults', defaults, varargin{:});
xilinx = get_var('xilinx', 'defaults', defaults, varargin{:});


inport = xInport('in');
sync_in = xInport('sync_in');
outports = cell(1,n_outputs);
for i =1:n_outputs
    outports{i} = xOutport(['out',num2str(i)]);
end
sync_out = xOutport('sync_out');


delay_ins = cell(1, n_outputs);
delay_blks = cell(1, n_outputs-1);
delay_ins{1} = inport;
for i =1:n_outputs-1
    delay_ins{i+1} = xSignal(['delay_in',num2str(i+1)]);
    delay_blks{i} = xBlock(struct('source', 'Delay', 'name', ['delay_blk', num2str(i)]), ...
                         {'latency', sample_period}, ...
                         delay_ins(i), ...
                         delay_ins(i+1));
end

downsample_blks = cell(1, n_outputs);
downsample_sync_outs = cell(1, n_outputs);
if xilinx
    downsample_sync_outs{1} = xSignal('downsample_sync_out');
    sync_delay_block = xBlock(struct('source', 'Delay', 'name', 'sync_delay_block'), ...
                                    struct('latency', 1), ...
                                    {sync_in}, ...
                                    downsample_sync_outs(1));
    for i =1:n_outputs
        downsample_blks{i} = xBlock(struct('source', 'xbsBasic_r4/Down Sample', 'name', ['Down_sample',num2str(i)]), ...
                                       struct('sample_ratio',  n_outputs, ...
                                              'sample_phase','Last Value of Frame  (most efficient)', ...
                                              'latency', 1), ...
                                  delay_ins(i), ...
                                  outports(n_outputs-i+1));
    end
else
    for i = 1:n_outputs
        downsample_sync_outs{i} = xSignal(['downsample_sync_out', num2str(i)]);
        downsample_blks{i} = xBlock(struct('source', str2func('downsample_init_xblock'), 'name', ['Down_sample',num2str(i)]), ...
                                       {[blk, '/','Down_sample',num2str(i)], 'dec_rate',n_outputs,'input_clk_rate', sample_period}, ...
                                  [delay_ins(i),{sync_in}], ...
                                  [outports(n_outputs-i+1),downsample_sync_outs(i)]);
    end   
end
                        
                        
sync_out.bind(downsample_sync_outs{1});
                        
if ~isempty(blk) && ~strcmp(blk(1),'/')
    fmtstr =sprintf('Sample Period = %d',sample_period);
    set_param(blk,'AttributesFormatString',fmtstr);
    clean_blocks(blk);
end
end


