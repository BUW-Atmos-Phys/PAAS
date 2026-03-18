function plot_bg_diff_timeseries_hist(BG_baseline, stats, component, time_av, plotfolder)

wavelength = stats.wavelength;
n_wl = length(wavelength);

graph = figure("Position",[0 0 1000 650]);

for i = 1:n_wl

    wl = wavelength(i);

    sigma = stats.(component).rmse(i)*1e6;
    mu    = stats.(component).mean(i)*1e6;

    laser_color = wavelength2color(wl,'gammaVal',1,'maxIntensity',1,'colorSpace','rgb');

    diff_var = sprintf("diff_BG_%s_%d",component,wl);

    y0 = 0.77 - (i-1)*0.21;

    %% Time series
    subplot('Position',[0.075 y0 0.68 0.2])

    plot(BG_baseline.Time, BG_baseline.(diff_var)*1e6,'.','Color',laser_color)

    hold on

    plot([BG_baseline.Time(1) BG_baseline.Time(end)],[2*sigma 2*sigma],'--k','LineWidth',3)
    plot([BG_baseline.Time(1) BG_baseline.Time(end)],[-2*sigma -2*sigma],'--k','LineWidth',3)

    grid on
    set(gca,'FontSize',16,'YMinorTick','on','LineWidth',1.5)

    ylim([-1.99 1.99])
    xlim([BG_baseline.Time(1) BG_baseline.Time(end)])

    ylabel('b_{abs} [Mm^{-1}]')

    if i < n_wl
        set(gca,'XTickLabel',[])
    else
        xlabel('Time')
    end

    legend(sprintf('%d nm',wl),'Location','northeast','FontSize',14)

    %% Histogram
    subplot('Position',[0.76 y0 0.2 0.2])

    x = BG_baseline.(diff_var)*1e6;

    histogram(x,50,'FaceColor',laser_color,'EdgeColor','none','Normalization','pdf')

    hold on

    y = -4:0.001:4;
    f = exp(-(y-mu).^2./(2*sigma^2))./(sigma*sqrt(2*pi));

    plot(y,f,'LineWidth',2.5,'Color',laser_color)

    grid on
    set(gca,'FontSize',12,'XMinorTick','on','XTickLabel',[], ...
        'YTickLabel',[],'LineWidth',1.5,'View',[90 -90])

    legend({'Histogram','Normal PDF'},'Location','northeast','FontSize',14)

    xlim([-1.99 1.99])
    ylim([0 3.5])

    annotation(graph,'textbox',...
        [0.8 y0+0.03 0.15 0.03],...
        'String',"2σ = "+string(round(2.*sigma,2))+" Mm^{-1}",...
        'LineStyle','-',...
        'FontSize',16,...
        'BackgroundColor','w',...
        'VerticalAlignment','middle',...
        'HorizontalAlignment','center');

end

set(gcf,'paperpositionmode','auto')

%print(plotfolder + "BGDiff_"+component+"_analysis_"+string(time_av)+"h.png",'-dpng')

end