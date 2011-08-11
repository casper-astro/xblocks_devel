%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011    Hong Chen   (based on GAVRT library uncram block)   %
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
function cram_init_xblock(blk, num_slice)


%% inports
inports = cell(1,num_slice);
for i =1:num_slice
    inports{i} = xInport(['In',num2str(i)]);
end

%% outports
xlsub2_Out = xOutport('Out');

%% diagram


if num_slice ==1
    xBlock(struct('source','Reinterpret','name','reinterpret'), ...
            {force_arith_type', 'on', 'arith_type', 'Unsigned', 'force_bin_pt', 'on', ...
          'bin_pt', 0}, ...
          inports,...
          {xlsub2_Out});
else
    reinterp_outs = cell(1,num_slice);
    reinterp_blks = cell(1,num_slice);
    for i =1:num_slice
        reinterp_outs{i} = xSignal;
        reinterp_blks{i} = xBlock(struct('source', 'Reinterpret', 'name', ['Reinterp',num2str(i)]), ...
                          struct('force_arith_type', 'on', 'arith_type', 'Unsigned', 'force_bin_pt', 'on', ...
                                 'bin_pt', 0), ...
                          {inports{i}}, ...
                          {reinterp_outs{i}});
    end
    concat = xBlock(struct('source', 'Concat', 'name', 'Concat'), ...
                       struct('num_inputs', num_slice), ...
                       reinterp_outs, ...
                       {xlsub2_Out});
end

if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
end

end

