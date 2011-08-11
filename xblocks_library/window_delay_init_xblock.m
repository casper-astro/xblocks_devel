%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda    Hong Chen                               %
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
function window_delay_init_xblock(blk, delay)


%% inports
xlsub2_in = xInport('in');

%% outports
xlsub2_out = xOutport('out');

%% diagram

% block: delay_7/window_delay/Gateway Out2
xlsub2_sync_delay1_out1 = xSignal;
xlsub2_Gateway_Out2_out1 = xSignal;
xlsub2_Gateway_Out2 = xBlock(struct('source', 'Gateway Out', 'name', 'Gateway Out2'), ...
                             [], ...
                             {xlsub2_sync_delay1_out1}, ...
                             {xlsub2_Gateway_Out2_out1});

% block: delay_7/window_delay/Gateway Out3
xlsub2_Register_out1 = xSignal;
xlsub2_Gateway_Out3_out1 = xSignal;
xlsub2_Gateway_Out3 = xBlock(struct('source', 'Gateway Out', 'name', 'Gateway Out3'), ...
                             [], ...
                             {xlsub2_Register_out1}, ...
                             {xlsub2_Gateway_Out3_out1});

% block: delay_7/window_delay/Gateway Out55
xlsub2_Gateway_Out55_out1 = xSignal;
xlsub2_Gateway_Out55 = xBlock(struct('source', 'Gateway Out', 'name', 'Gateway Out55'), ...
                              [], ...
                              {xlsub2_in}, ...
                              {xlsub2_Gateway_Out55_out1});

% block: delay_7/window_delay/Gateway Out56
xlsub2_sync_delay_out1 = xSignal;
xlsub2_Gateway_Out56_out1 = xSignal;
xlsub2_Gateway_Out56 = xBlock(struct('source', 'Gateway Out', 'name', 'Gateway Out56'), ...
                              [], ...
                              {xlsub2_sync_delay_out1}, ...
                              {xlsub2_Gateway_Out56_out1});

% block: delay_7/window_delay/Register
xlsub2_Register = xBlock(struct('source', 'Register', 'name', 'Register'), ...
                         struct('rst', 'on', ...
                                'en', 'on'), ...
                         {xlsub2_sync_delay_out1, xlsub2_sync_delay1_out1, xlsub2_sync_delay_out1}, ...
                         {xlsub2_Register_out1});


% block: delay_7/window_delay/negedge
xlsub2_negedge_out1 = xSignal;
xlsub2_negedge = xBlock(struct('source', 'casper_library_misc/negedge', 'name', 'negedge'), ...
                        [], ...
                        {xlsub2_in}, ...
                        {xlsub2_negedge_out1});

% block: delay_7/window_delay/posedge3
xlsub2_posedge3_out1 = xSignal;
xlsub2_posedge3 = xBlock(struct('source', 'casper_library_misc/posedge', 'name', 'posedge3'), ...
                         [], ...
                         {xlsub2_in}, ...
                         {xlsub2_posedge3_out1});

% block: delay_7/window_delay/sync_delay
xlsub2_sync_delay = xBlock(struct('source', str2func('sync_delay_init_xblock'), 'name', 'sync_delay'), ...
                           {[blk,'/sync_delay'], delay-1}, ...
                           {xlsub2_posedge3_out1}, ...
                           {xlsub2_sync_delay_out1});

% block: delay_7/window_delay/sync_delay1
xlsub2_sync_delay1 = xBlock(struct('source', str2func('sync_delay_init_xblock'), 'name', 'sync_delay1'), ...
                            {[blk,'/sync_delay1'],delay-1}, ...
                            {xlsub2_negedge_out1}, ...
                            {xlsub2_sync_delay1_out1});

% extra outport assignment
xlsub2_out.assign(xlsub2_Register_out1);

if ~isempty(blk) && ~strcmp(blk(1), '/')
    clean_blocks(blk);
end

end

