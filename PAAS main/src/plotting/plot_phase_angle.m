function hFig = plot_phase_angle(b_abs, alpha, laser_wavelength, plotfolder)
    
    hFig = figure('Color','w','Units','normalized','Position',[0.2 0.2 0.3 0.4]);
    tiledlayout(2,2,'TileSpacing','compact','Padding','compact')
    
    for i = 1:4
        
        nexttile
        hold on
        
        c = wavelength2color(laser_wavelength(i));
        
        h_sc = scatter(alpha(i,:), 1e6.*b_abs(i,:), 22, ...
            'MarkerFaceColor',c, ...
            'MarkerEdgeColor','none', ...
            'MarkerFaceAlpha',0.6);

        % ±10 degree lines
        h_line = xline(-10,'--k','LineWidth',1.3);   % shown in legend
        xline(10,'--k','LineWidth',1.3,'HandleVisibility','off');
        
        xlabel('phase angle, \alpha','FontSize',14)
        ylabel('b_{abs} [Mm^{-1}]','FontSize',14)
        
        title(sprintf('%d nm',laser_wavelength(i)),'FontSize',14)
        
        grid on
        box on
        set(gca,'LineWidth',1.2,'FontSize',14, 'FontName', 'DejaVu Sans')
        % legend
        legend([h_sc h_line], ...
            {sprintf('%d nm',laser_wavelength(i)),'\pm 10°'}, ...
            'Location','best','FontSize',14)
    end

    filename = fullfile(plotfolder,'PhaseAngle.png'); 
    print(filename,'-dpng')

end