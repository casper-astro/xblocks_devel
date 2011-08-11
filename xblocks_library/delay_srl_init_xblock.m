%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011      Hong Chen                                         %
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
function delay_srl_init_xblock(blk, DelayLen)
% Mask Initialization code
if (DelayLen > 0),
    ff_delay = 1;
    srl_delay = DelayLen - 1;
else
    ff_delay = 0;
    srl_delay = 0;
end

%% inports
xlsub2_in = xInport('in');

%% outports
xlsub2_out = xOutport('out');

%% diagram

% block: untitled/delay_srl/delay_ff
xlsub2_delay_ff_out1 = xSignal;
xlsub2_delay_ff = xBlock(struct('source', 'Delay', 'name', 'delay_ff'), ...
                         struct('latency', ff_delay), ...
                         {xlsub2_in}, ...
                         {xlsub2_delay_ff_out1});

% block: untitled/delay_srl/delay_srl
xlsub2_delay_srl = xBlock(struct('source', 'Delay', 'name', 'delay_srl'), ...
                          struct('latency', srl_delay), ...
                          {xlsub2_delay_ff_out1}, ...
                          {xlsub2_out});

if ~isempty(blk) && ~strcmp(blk(1), '/')
    clean_blocks(blk);
end

end

