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
function dsp_scope_init_xblock(blk, varargin)

defaults = {...
    'n_inputs',8, ...
    'slice_width', 8, ...
    'bin_pt', 7, ...
    'arith_type', 1, ...
    'sample_period',1};

n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
slice_width = get_var('slice_width', 'defaults', defaults, varargin{:});
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});
arith_type = get_var('arith_type', 'defaults', defaults, varargin{:});
sample_period = get_var('sample_period', 'defaults', defaults, varargin{:});


inport = xInport('in');

outport = xOutport('out');


uncram_out = cell(1,n_inputs);
for i =1:n_inputs
    uncram_out{i} = xSignal(['uncram_out',num2str(i)]);
end

% add uncram block                      
uncram = xBlock(struct('source', str2func('uncram_init_xblock'), 'name', 'uncram'), ...
                {[blk,'/uncram'], ...
                        'num_slice',n_inputs, ...
                        'slice_width', slice_width, ...
                        'bin_pt', bin_pt, ...
                        'arith_type', arith_type}, ...
                        {inport}, ...
                        uncram_out);

% add parallel scope block                    
parallel_scope = xBlock(struct('source', str2func('parallel_scope_init_xblock'), 'name', 'p_scope'), ...
                        {[blk,'/p_scope'], ...
                        'n_inputs', n_inputs, ...
                        'sample_period', sample_period}, ...
                        uncram_out, ...
                        {outport});

                        
                        
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    fmtstr = sprintf('Fix_%d_%d\n%d inputs\nSample Period%d', slice_width, bin_pt, n_inputs, sample_period);
    set_param(blk, 'AttributesFormatString', fmtstr);
end

end


