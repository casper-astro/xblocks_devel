function twiddle_stage_2_init_xblock(a_re, a_im, b_re, b_im, sync, ...
    a_re_out, a_im_out, bw_re_out, bw_im_out, sync_out, ...
    FFTSize, input_bit_width, negate_latency)
%% diagram

negate_out1 = xSignal;
convert_out1 = xSignal;
counter_out1 = xSignal;
sel = xSignal;
im_sel = xSignal;
delay3_out1 = xSignal;
delay4_out1 = xSignal;
b_re_bram_del = xSignal;
b_im_bram_del = xSignal;

% delay a_re by total delay 
a_re_del = xBlock(struct('source', 'Delay', 'name', 'a_re_del'), ...
                       struct('latency', negate_latency, 'reg_retiming', 'on'), {a_re}, {a_re_out});

% delay a_im by total delay
a_im_del = xBlock(struct('source', 'Delay', 'name', 'a_im_del'), ...
                       struct('latency', negate_latency, 'reg_retiming', 'on'), {a_im}, {a_im_out});

% delay output sync pulse by total latency
sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
                       struct('latency', negate_latency), {sync}, {sync_out});

% negate bw_re to multiply by -j
negate = xBlock(struct('source', 'Negate', 'name', 'negate'), ...
                       struct('n_bits', input_bit_width, 'bin_pt', input_bit_width-1, 'overflow', 'Saturate', ...
                              'latency', negate_latency), ...
                       {b_re}, {bw_im_out});

% delay b_im to match bw_im_out
xBlock( struct('source', 'Delay', 'name', 'bw_im_del'), ...
        struct('latency', negate_latency'), {b_im}, {bw_re_out} );

end

