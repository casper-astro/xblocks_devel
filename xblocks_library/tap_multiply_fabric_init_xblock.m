%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda                                            %
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

%% TODO
function tap_multiply_fabric_init_xblock(blk, n_bits_a, bin_pt_a, n_bits_b, bin_pt_b, full_precision, n_bits_c, bin_pt_c, quantization, overflow, cast_latency, n_taps, mult_latency)

for k = 1:n_taps
    a = xInport( ['a', num2str(k)] );
    b = xInport( ['b', num2str(k)] );
    c = xOutport( ['c', num2str(k)] );
    
    xBlock( struct('source', 'Mult', 'name', ['mult_', num2str(k)]), ...
        struct('latency', mult_latency, 'precision', 'Full', ...
            'quantization', quantization, 'overflow', overflow), ...
        {a, b}, {c} );
    
end
