function plot_timeseries_histogram(TT_statistics, ...
                                     stats, ...
                                     laser_wavelength, ...
                                     time_av, ...
                                     time_range)
% Time series with right-side histograms
% Width ratio TimeSeries:Histogram = 3:1
% Units: Mm^-1

    n_laser = length(laser_wavelength);
    conversion = 1e6; % 1/m -> Mm^-1

    % ---------------------------------------------------------
    % Optional limits
    % ---------------------------------------------------------
    if nargin < 5 || isempty(time_range)
        time_range = [TT_statistics.Time(1), TT_statistics.Time(end)];
    end

    % ---------------------------------------------------------
    % Wavelength colors
    % ---------------------------------------------------------
    laser_color = NaN(n_laser,3);
    for i = 1:n_laser
        laser_color(i,:) = wavelength2color( ...
            laser_wavelength(i), ...
            'gammaVal',1, ...
            'maxIntensity',1, ...
            'colorSpace','rgb');
    end

    % ---------------------------------------------------------
    % Figure geometry
    % ---------------------------------------------------------
    figure('Color','w','Units','normalized','Position',[0.1 0.1 0.75 0.8]);

    left_margin   = 0.08;
    right_margin  = 0.04;
    top_margin    = 0.05;
    bottom_margin = 0.07;
    vertical_gap  = 0.02;
    horizontal_gap = 0.02;

    total_width = 1 - left_margin - right_margin - horizontal_gap;
    ts_width  = total_width * 0.75;  % 3/4
    hist_width = total_width * 0.25; % 1/4

    total_height = 1 - top_margin - bottom_margin;
    row_height = (total_height - (n_laser-1)*vertical_gap) / n_laser;

    for i = 1:n_laser

        wl = num2str(laser_wavelength(i));
        varname = ['mean_' wl];
        
        b_plot = TT_statistics.(varname) .* conversion;
        time = TT_statistics.Time;
        sigma = stats.X.rmse(i)*1e6;

        bottom = 1 - top_margin - i*row_height - (i-1)*vertical_gap;

        % ============================
        % Time series axis (3x width)
        % ============================
        ax_ts = axes('Position', ...
            [left_margin, bottom, ts_width, row_height]);
        hold on

        plot(time, b_plot, ...
            'LineWidth',1.5, ...
            'Color',laser_color(i,:));

        % LOD
        yline(2.*sigma,'--k','LineWidth',3);

        grid on
        box on
        set(gca,'FontSize',14,'LineWidth',1.1)

        xlim([datetime(time_range(1)), datetime(time_range(2))])
        ylim([0 Inf])

        ylabel({[wl ' nm'], 'b_{abs} [Mm^{-1}]'})

        if i ~= n_laser
            set(gca,'XTickLabel',[])
        else
            xlabel('Time')
        end

        % ============================
        % Histogram axis (1x width)
        % ============================
        ax_hist = axes('Position', ...
            [left_margin + ts_width + horizontal_gap, ...
             bottom, ...
             hist_width, ...
             row_height]);
        hold on

        histogram(b_plot, ...
            'Normalization','pdf', ...
            'Orientation','horizontal', ...
            'FaceColor',laser_color(i,:), ...
            'EdgeColor','none', ...
            'FaceAlpha',0.6);

        grid on
        box on
        set(gca,'FontSize',14,'LineWidth',1.1)

        ylim([0 Inf])
        xlabel('PDF')
        set(gca,'YTickLabel',[])

        linkaxes([ax_ts ax_hist],'y')

    end

    sgtitle(sprintf('Aerosol Absorption Coefficient (%d h average)', time_av), ...
            'FontSize',18, ...
            'FontWeight','normal')

end