function xblock_delay( din, dout, name, latency, delay_type )

if length(din) ~= length(dout)
	error('delaying unequal buses')
end

[M,N] = size(din)

for m = 1:M
    for n =1:N
	    xBlock( struct('source', 'Delay', 'name', [name, '_delay_', num2str(m), '_', num2str(n)]), ...
	    	struct('latency', latency), {din{m,n}}, {dout{m,n}});
    end
end

end
