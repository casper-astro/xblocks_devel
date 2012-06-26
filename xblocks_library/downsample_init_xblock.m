%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2012    Hong Chen                                           %
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
% dec_rate: effective rate change
% explicit_clk_rate: whether to use explicit clk rate in the counter
% input_clk_period: the actual sampling period of the input signal
% input_period: the supposed sampling period of the input signal
%            has to be a multiple of input_clk_period
% xilinx: whether to use xilinx downsample block (multirate system)
function downsample_init_xblock(blk, varargin)

defaults = {'dec_rate', 3, ...
    'explicit_clk_rate', 'on', ...
    'input_clk_period', 1, ...
    'input_period', 1, ...
    'xilinx',0, ...
    'ext_en', 'off'};   % default: 0, don't use the xilinx cic, this is just for the convenience of testing

dec_rate = get_var('dec_rate', 'defaults', defaults, varargin{:});
explicit_clk_rate = get_var('explicit_clk_rate', 'defaults', defaults, varargin{:}); 
    % when this is off, infer clock rate from input, then input_clk_period is pratically disabled
input_clk_period = get_var('input_clk_period', 'defaults', defaults, varargin{:});
input_period = get_var('input_period', 'defaults', defaults, varargin{:});
xilinx = get_var('xilinx', 'defaults', defaults, varargin{:});
ext_en = get_var('ext_en', 'defaults', defaults, varargin{:});


%% inports
inport = xInport('In');

%% outports
outport = xOutport('Out');


if mod(input_period/input_clk_period,1)
    disp('input_period must be a multiple of input_clk_period');
    sync_in = xInport('sync_in');
    sync_out = xOutport('sync_out');
    downsample_one_pass_through(blk, inport, sync_in, outport, sync_out, dec_rate, input_clk_period, input_period);
    return;
end


if dec_rate ==1 && (input_period/input_clk_period) == 1
    sync_in = xInport('sync_in');
    sync_out = xOutport('sync_out');
    downsample_one_pass_through(blk, inport, sync_in, outport, sync_out, dec_rate, input_clk_period, input_period);
    return;
end

%% diagram
if xilinx
    sync_in = xInport('sync_in');
    sync_out = xOutport('sync_out');
    downsample = xBlock(struct('source','xbsIndex/Down Sample', 'name', 'xDownSample'), ...
                        struct('sample_ratio', dec_rate, ...
                        'sample_phase', 'Last Value of Frame  (most efficient)'), ...
                        {inport}, ...
                        {outport});
    sync_out.bind(sync_in);
    return;
    
elseif strcmp(ext_en, 'off')
    en = xSignal('en');
    sync_in = xInport('sync_in');
    sync_out = xOutport('sync_out');
    hold_en = xBlock(struct('source', str2func('hold_en_init_xblock'), 'name', 'en_gen'), ...
             {[blk, '/en_gen'], ...
              'hold_period', dec_rate*(input_period/input_clk_period), ...
              'explicit_clk_rate', explicit_clk_rate, ...
              'input_clk_period', input_clk_period}, ...
             {sync_in}, ...
             {en});
         
    % block: my_downsample/downsample_init_xblock/Register
    Relational_out = xSignal;
    Register = xBlock(struct('source', 'Register', 'name', 'Register'), ...
                             struct('en', 'on'), ...
                             {inport, en}, ...
                             {outport});

    % block: sync delay
    Sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
        struct('latency',1), ...
        {sync_in}, ...
        {sync_out});

else
    
    en_in = xInport('en_in');
    en_out = xOutport('en_out');
    % block: my_downsample/downsample_init_xblock/Register
    Relational_out = xSignal;
    Register = xBlock(struct('source', 'Register', 'name', 'Register'), ...
                             struct('en', 'on'), ...
                             {inport, en_in}, ...
                             {outport});

    % block: sync delay
    Sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
        struct('latency',1), ...
        {en_in}, ...
        {en_out});
  
end


if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    fmtstr=sprintf('Rate change: %d\nclock(actualy/effective): %d/%d',dec_rate, input_clk_period, input_period);
    set_param(blk,'AttributesFormatString',fmtstr);
end
end

function downsample_one_pass_through(blk, data_inport, sync_or_en_inport, data_outport, sync_outport, dec_rate, input_clk_period, input_period)


xConnector(data_outport, data_inport);
xConnector(sync_outport, sync_or_en_inport);

if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    if dec_rate ~= 1
        fmtstr=sprintf('Pass-through\nRate change :%d (forced to 1)\nclock(actualy/effective): %d/%d',dec_rate, input_clk_period, input_period);
    else
        fmtstr=sprintf('Pass-through\nRate change :1\nclock(actualy/effective): %d/%d',input_clk_period, input_period);
    end
    set_param(blk,'AttributesFormatString',fmtstr);
end

end