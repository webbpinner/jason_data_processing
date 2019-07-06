divestr = 'J2-638';

inct1 = sprintf('%s.CTD.raw', divestr)
  ct1 = read_ctd(inct1);

inct2 = sprintf('%s.CT2.raw', divestr)
  ct2 = read_ct2(inct2);

figure(1)

plot(ct1.tm, ct1.conductivity,'k-.', ct2.tm, ct2.conductivity, 'b:')
titlestr = sprintf('Jason CTDs: Conductivity vs. Time, Dive %s', divestr); 
title(titlestr)
legend('Legacy', 'New')
xlabel('Time (minutes)')
ylabel('Conductivity')
filename = sprintf('%s_cond.png', divestr)
saveas(gcf, filename, 'png')

figure(2)
plot(ct1.tm, ct1.temperature, 'k-.', ct2.tm, ct2.temperature, 'b:')
titlestr = sprintf('Jason CTDs: Temperature vs. Time, Dive %s', divestr); 
title(titlestr)
legend('Legacy', 'New')
xlabel('Time (minutes)')
ylabel('Temp, degC')
axis ij
filename = sprintf('%s_temp.png', divestr)
saveas(gcf, filename, 'png')

figure(3)
plot(ct1.tm, -1*ct1. depth, 'k-.', ct2.tm, -1*ct2. depth, 'b:')
titlestr = sprintf('Jason CTDs: Depth vs. Time, Dive %s', divestr); 
title(titlestr)
legend('Legacy', 'New')
xlabel('Time (minutes)')
ylabel('Depth, m')
filename = sprintf('%s_dep.png', divestr)
saveas(gcf, filename, 'png')

figure(4)
plot(-1*ct1. depth, ct1.conductivity,'k-.', -1*ct2.depth, ct2.conductivity,'b:')
titlestr = sprintf('Jason CTDs: Conductivity vs. Depth, Dive %s', divestr); 
title(titlestr)
legend('Legacy', 'New')
xlabel('Time (minutes)')
ylabel('Depth, m')
filename = sprintf('%s_dep.png', divestr)
saveas(gcf, filename, 'png')

figure(5)
plot(-1*ct1. depth, ct1.temperature,'k-.', -1*ct2.depth, ct2.temperature,'b:')
titlestr = sprintf('Jason CTDs: Temperature vs. Depth, Dive %s', divestr); 
title(titlestr)
legend('Legacy', 'New')
xlabel('Time (minutes)')
ylabel('Depth, m')
filename = sprintf('%s_dep.png', divestr)
saveas(gcf, filename, 'png')

figure(6)


