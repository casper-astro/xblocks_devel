function xblock_delay( din, dout, name, latency, delay_type )

if length(din) ~= length(dout)
	error('delaying unequal buses')
end

for k = 1:length(din)
	xBlock( struct('source', 'Delay', 'name', [name, 'delay_', num2str(k)]), ...
		struct('latency', latency), {din{k}}, {dout{k}});
end

end
