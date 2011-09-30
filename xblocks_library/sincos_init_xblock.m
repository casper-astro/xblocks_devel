% Generate sine/cos.
%
% sinecos_init(blk, varargin)
%
% blk = The block to be configured.
% varargin = {'varname', 'value', ...} pairs
%
% Valid varnames for this block are:

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

function sincos_init_xblock(blk,varargin)


defaults = {};
func = get_var('func', 'defaults', defaults, varargin{:});
neg_sin = get_var('neg_sin', 'defaults', defaults, varargin{:});
neg_cos = get_var('neg_cos', 'defaults', defaults, varargin{:});
bit_width = get_var('bit_width', 'defaults', defaults, varargin{:});
symmetric = get_var('symmetric', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
depth_bits = get_var('depth_bits', 'defaults', defaults, varargin{:});
handle_sync = get_var('handle_sync', 'defaults', defaults, varargin{:});

%handle the sync
if strcmp(handle_sync, 'on'),
    sync_in = xInport('sync_in');
    sync_out = xOutport('sync_out');
    xBlock( struct('source', 'Delay', 'name', 'sync_delay'), ...
                      {'latency', bram_latency}, ...
                      { sync_in }, { sync_out });
end

%input and output ports
inport = xInport('theta');

%draw first lookup
if( strcmp(func, 'sine and cosine') || strcmp(func, 'sine') ),
    if strcmp(neg_sin, 'on') , sin_name = '-sine'; else sin_name = 'sine'; end
    outport_sin = xOutport(sin_name);
end
if( strcmp(func, 'sine and cosine') || strcmp(func, 'cosine')),
    if strcmp(neg_cos, 'on') , cos_name = '-cos'; else cos_name = 'cos'; end
    %if strcmp(func, 'sine and cosine') pos = '3'; end
    outport_cos = xOutport(cos_name);
end

%lookup for sine/cos
if( strcmp(func, 'sine') || strcmp(func, 'sine and cosine') ),
    if strcmp(neg_sin, 'on')  
        init_vec = -sin(2*pi*(0:(2^depth_bits-1))/(2^depth_bits));
    else
        init_vec = sin(2*pi*(0:(2^depth_bits-1))/(2^depth_bits));
    end
else 
    if( strcmp(neg_cos, 'on') )
        init_vec = -cos(2*pi*(0:(2^depth_bits-1))/(2^depth_bits));
    else
        init_vec = cos(2*pi*(0:(2^depth_bits-1))/(2^depth_bits));
    end
end

bin_pt = bit_width-1;
if(strcmp(symmetric, 'on'))
    bin_pt = bit_width-2; 
end
rom0_out = xSignal('rom0_out');
rom0_blk = xBlock(struct('source',  'xbsIndex_r4/ROM', 'name', 'rom0'), ...
    {'depth', 2^depth_bits, 'initVector', init_vec, ...
    'latency', bram_latency, 'n_bits', bit_width, ...
    'bin_pt', bin_pt}, ...
    {inport}, ...
    {rom0_out});

if (strcmp(func, 'sine and cosine') || strcmp(func, 'sine'))
    outport_sin.bind(rom0_out);
else
    outport_cos.bind(rom0_out);
end

%have 2 outputs
if strcmp(func, 'sine and cosine')
    if( strcmp(neg_cos, 'on') )
        init_vec = -cos(2*pi*(0:(2^depth_bits-1))/(2^depth_bits));
    else
        init_vec = cos(2*pi*(0:(2^depth_bits-1))/(2^depth_bits));
    end

    rom1_blk = xBlock(struct('source', 'xbsIndex_r4/ROM','name', 'rom1'), ...
        {'depth', 2^depth_bits, 'initVector', init_vec, ...
        'latency', bram_latency, 'n_bits', bit_width, ...
        'bin_pt', bin_pt}, ...
        {inport}, ...
        {outport_cos});
end

% Set attribute format string (block annotation)
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    annotation=sprintf('depth_bits = %d\nbit_width = %d\n%bin_pt = %d', depth_bits, bit_width, bin_pt);
    set_param(blk,'AttributesFormatString',annotation);
end

end