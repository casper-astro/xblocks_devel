%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
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
function pipeline_init_xblock(blk, latency)



%% inports
xlsub2_d = xInport('d');

%% outports
xlsub2_q = xOutport('q');

%% diagram

if (latency==0)
    xlsub2_q.bind(xlsub2_d);
else
    prev=xlsub2_d;
    next=xSignal;
    for i=1:latency,
        xlsub2_Register.(['R',num2str(i-1)]) = xBlock(struct('source', 'Register', 'name', ['Register',num2str(i-1)]), ...
                                             [], ...
                                             {prev}, ...
                                             {next});
        prev=xSignal;
        prev.bind(next);
        next=xSignal;
    end
    xlsub2_q.bind(prev);
end
    
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    annotation = sprintf('Latency = %d',latency);
    set_param(blk, 'AttributesFormatString', annotation);
end
    
% % block: delay_7/pipeline/Register0
% xlsub2_Register0_out1 = xSignal;
% xlsub2_Register0 = xBlock(struct('source', 'Register', 'name', 'Register0'), ...
%                           [], ...
%                           {xlsub2_d}, ...
%                           {xlsub2_Register0_out1});
% 
% % block: delay_7/pipeline/Register1
% xlsub2_Register1 = xBlock(struct('source', 'Register', 'name', 'Register1'), ...
%                           [], ...
%                           {xlsub2_Register0_out1}, ...
%                           {xlsub2_q});
% 


end

