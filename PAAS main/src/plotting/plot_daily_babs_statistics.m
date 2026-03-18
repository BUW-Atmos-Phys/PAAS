function plot_daily_babs_statistics(time,b_abs,laser_wavelength)

n_laser = length(laser_wavelength);

time = time(:); % ensure column

figure('Position',[10 10 1300 900],'Units','pixels')

for i = 1:n_laser

    % select valid data
    y = b_abs(i,:)';
    valid = ~isnan(y) & ~isnat(time);

    t = time(valid);
    y = y(valid);

    % convert to daily categories
    day_cat = categorical(dateshift(t,'start','day'));

    % reduce tick labels
    max_labels = 20;
    Xlabels = unique(day_cat);
    n_labels = numel(Xlabels);
    labelspace = max(1, ceil(n_labels / max_labels));
    Xlabel_red = Xlabels(1:labelspace:end);

    subplot(n_laser,1,i)

    laser_color = wavelength2color(laser_wavelength(i),...
        'gammaVal',1,'maxIntensity',1,'colorSpace','rgb');

    boxchart(day_cat,y*1e6,...
        'BoxFaceColor',laser_color,...
        'MarkerColor',laser_color,...
        'MarkerStyle','+')

    hold on

    mean_daily = groupsummary(y*1e6,day_cat,'mean');

    plot(mean_daily,'-o',...
        'MarkerSize',5,...
        'MarkerEdgeColor',laser_color,...
        'MarkerFaceColor','w',...
        'Color',laser_color,...
        'LineWidth',1.5)

    ylabel('b_{abs} [Mm^{-1}]')

    legend(['Range ' num2str(laser_wavelength(i)) ' nm'],'Mean',...
        'Location','northeast')

    set(gca,...
        'FontSize',14,...
        'LineWidth',1.5,...
        'XTick',Xlabel_red)

    if i ~= n_laser
        set(gca,'XTickLabel',[])
    end

    grid on
    box on

end

end