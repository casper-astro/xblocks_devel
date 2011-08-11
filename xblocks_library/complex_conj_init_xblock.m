%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda, Hong Chen                                 %
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
function complex_conj_init_xblock(blk, bitwidth, bin_pt, latency, mode)

in = xInport('z');
out = xOutport('z*');

in_real = xSignal;
in_imag = xSignal;
out_real = xSignal;
out_imag = xSignal;

c_to_ri_config.source = str2func('c_to_ri_init_xblock');
c_to_ri_config.name = 'c_to_ri';

xBlock( c_to_ri_config, ...
    {[blk,'/',c_to_ri_config.name],bitwidth,  bin_pt}, ...
    {in}, ...
    {in_real, in_imag} );

if strcmp(mode, 'dsp48e')
    latency = 3;
end

delay_config.source = 'Delay';
delay_config.name = 'real_delay';
xBlock( delay_config, struct('latency', latency), ...
    {in_real}, ...
    {out_real} );

negate_config.source = str2func('negate_init_xblock');
negate_config.name = 'imag_negate';
xBlock( negate_config, {[blk, '/',negate_config.name],bitwidth, bin_pt, latency, mode}, ...
    {in_imag}, ...
    {out_imag} );

ri_to_c_config.source = str2func('ri_to_c_init_xblock');
ri_to_c_config.name = 'ri_to_c';
xBlock( ri_to_c_config, {}, {out_real, out_imag}, {out});

if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
end

end