%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011                Hong Chen                               %
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

function delay_general_init_xblock(delaytype, varargin)



switch delaytype
	case 'delay_bram'
		In1 = xInport('In1');
		Out1 = xOutport('Out1');
		defaults = {'DelayLen',6,'bram_latency',2,'use_dsp48','off'};
		DelayLen = get_var('DelayLen', 'defaults', defaults, varargin{:});
		bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
		use_dsp48 = get_var('use_dsp48', 'defaults', defaults, varargin{:});
		delay_bram_config.source=str2func('delay_bram_init_xblock');
		delay_bram_config.name = 'delay_bram';
		delay_bram_sub = xBlock(delay_bram_config,{DelayLen,bram_latency,use_dsp48});
		delay_bram_sub.bindPort({In1},{Out1});
	case 'delay_slr'
		In1 = xInport('In1');
		Out1 = xOutport('Out1');
		defaults = {'DelayLen',6};
		DelayLen = get_var('DelayLen', 'defaults', defaults, varargin{:});
		delay_slr_config.source=str2func('delay_slr_init_xblock');
		delay_slr_config.name = 'delay_slr';
		delay_slr_sub = xBlock(delay_slr_config,{DelayLen});
		delay_slr_sub.bindPort({In1},{Out1});
	case 'sync_delay'
		In1 = xInport('In');
		Out1 = xOutport('Out');
		defaults = {'DelayLen',6};
		DelayLen = get_var('DelayLen', 'defaults', defaults, varargin{:});
		sync_delay_config.source=str2func('sync_delay_init_xblock');
		sync_delay_config.name = 'sync_delay';
		sync_delay_sub = xBlock(sync_delay_config,{DelayLen});
		sync_delay_sub.bindPort({In1},{Out1});
	case 'sync_delay_en'
        In1 = xInport('In');
        In2 = xInport('en');
        Out = xOutport('Out');
		%{In1,In2}
		defaults = {'DelayLen',6};
		DelayLen = get_var('DelayLen', 'defaults', defaults, varargin{:});
		sync_delay_en_config.source=str2func('sync_delay_en_init_xblock');
		sync_delay_en_config.name = 'sync_delay_en';
		sync_delay_en_sub = xBlock(sync_delay_en_config,{DelayLen});
		%names = sync_delay_en_sub.getInportNames
		sync_delay_en_sub.bindPort({In1,In2},{Out});
	case 'sync_delay_prog'
		Out = xOutport('sync_out');
		In1 = xInport('sync');
		In2 = xInport('delay');
		defaults = {'MaxDelay',7};
		MaxDelay = get_var('MaxDelay', 'defaults', defaults, varargin{:});
		sync_delay_prog_config.source=str2func('sync_delay_prog_init_xblock');
		sync_delay_prog_config.name = 'sync_delay_prog';
		sync_delay_prog_sub = xBlock(sync_delay_prog_config,{MaxDelay});
		sync_delay_prog_sub.bindPort({In1,In2},{Out});
	case 'window_delay'
		In1 = xInport('In');
		Out1 = xOutport('Out');
		defaults = {'DelayLen',2};
		DelayLen = get_var('DelayLen', 'defaults', defaults, varargin{:});
		window_delay_config.source=str2func('window_delay_init_xblock');
		window_delay_config.name = 'window_delay';
		window_delay_sub = xBlock(window_delay_config,{DelayLen});
		window_delay_sub.bindPort({In1},{Out1});
	case 'pipeline'
		In1 = xInport('d');
		Out1 = xOutport('q');
		defaults = {'DelayLen',7};
		DelayLen = get_var('DelayLen', 'defaults', defaults, varargin{:});
		pipeline_config.source=str2func('pipeline_init_xblock');
		pipeline_config.name = 'pipeline';
		pipeline_sub = xBlock(pipeline_config,{DelayLen});
		pipeline_sub.bindPort({In1},{Out1});
	otherwise
		disp('error! such delay block is not supported!');
		disp(delaytype);
end

end
		
