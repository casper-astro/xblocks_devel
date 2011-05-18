function tap_multiply_fabric_init_xblock(n_bits_a, bin_pt_a, n_bits_b, bin_pt_b, full_precision, n_bits_c, bin_pt_c, quantization, overflow, cast_latency, n_taps, mult_latency)

for k = 1:n_taps
    a = xInport( ['a', num2str(k)] );
    b = xInport( ['b', num2str(k)] );
    c = xOutport( ['c', num2str(k)] );
    
    xBlock( struct('source', 'Mult', 'name', ['mult_', num2str(k)]), ...
        struct('latency', mult_latency, 'precision', 'Full', ...
            'quantization', quantization, 'overflow', overflow), ...
        {a, b}, {c} );
    
end
