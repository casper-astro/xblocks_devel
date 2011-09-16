function signals = xblock_new_bus( M,N )

signals = {};
for n = 1:N
	for m = 1:M
		signals{m,n} = xSignal;
end

end