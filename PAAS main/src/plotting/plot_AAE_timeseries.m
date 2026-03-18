function plot_AAE_timeseries(TT_statistics, ...
                             laser_wavelength, ...
                             b_threshold, ...
                             time_range)
%PLOT_AAE_TIMESERIES
%
% Computes:
%   - AAE from log-log fit (all wavelengths)
%   - AAE smallest wavelength pair
%   - AAE largest wavelength pair
%
% Units:
%   b_threshold in Mm^-1
%
% Optional:
%   time_range  [t1 t2]

    n_laser = length(laser_wavelength);
    time = TT_statistics.Time;

    % ---------------------------------------------------------
    % Extract absorption (Mm^-1)
    % ---------------------------------------------------------
    B = NaN(n_laser, length(time));

    for i = 1:n_laser
        wl = num2str(laser_wavelength(i));
        B(i,:) = 1e6 .* TT_statistics.(['mean_' wl]).';
    end

    % Threshold
    B(B < b_threshold | B <= 0) = NaN;

    % ---------------------------------------------------------
    % 1) Log-log fit AAE
    % ---------------------------------------------------------
    AAE_fit = NaN(1,length(time));
    log_lambda = log10(laser_wavelength(:));

    for k = 1:length(time)
        y = log10(B(:,k));
        valid = ~isnan(y);

        if sum(valid) >= 2
            p = polyfit(log_lambda(valid), y(valid), 1);
            AAE_fit(k) = -p(1);
        end
    end

    % ---------------------------------------------------------
    % 2) Smallest wavelength pair
    % ---------------------------------------------------------
    [~,idx_sorted] = sort(laser_wavelength);

    idx_small = idx_sorted(1:2);
    wl_small  = laser_wavelength(idx_small);

    AAE_small = -log10( ...
        B(idx_small(1),:) ./ B(idx_small(2),:) ) ...
        ./ log10(wl_small(1) / wl_small(2));

    % ---------------------------------------------------------
    % 3) Largest wavelength pair
    % ---------------------------------------------------------
    idx_large = idx_sorted(end-1:end);
    wl_large  = laser_wavelength(idx_large);

    AAE_large = -log10( ...
        B(idx_large(1),:) ./ B(idx_large(2),:) ) ...
        ./ log10(wl_large(1) / wl_large(2));

    % ---------------------------------------------------------
    % Optional limits
    % ---------------------------------------------------------
    if nargin < 4 || isempty(time_range)
        time_range = [time(1), time(end)];
    end

    all_AAE = [AAE_fit, AAE_small, AAE_large];

    if nargin < 5 || isempty(aae_range)
        ymin = min(all_AAE,[],'omitnan');
        ymax = max(all_AAE,[],'omitnan');
        margin = 0.05*(ymax-ymin);
        aae_range = [ymin-margin, ymax+margin];
    end

    % ---------------------------------------------------------
    % Figure layout (3:1)
    % ---------------------------------------------------------
    figure('Color','w','Units','normalized','Position',[0.1 0.2 0.75 0.5]);

    left_margin   = 0.08;
    right_margin  = 0.04;
    bottom_margin = 0.15;
    top_margin    = 0.10;
    horizontal_gap = 0.03;

    total_width = 1 - left_margin - right_margin - horizontal_gap;
    ts_width  = total_width * 0.75;
    hist_width = total_width * 0.25;
    height = 1 - bottom_margin - top_margin;

    % ============================
    % Time series
    % ============================
    ax_ts = axes('Position', ...
        [left_margin, bottom_margin, ts_width, height]);
    hold on

    plot(time, AAE_fit, ...
        'k','LineWidth',2, ...
        'DisplayName','AAE (log-log fit)');

    plot(time, AAE_small, ...
        'r','LineWidth',1.5, ...
        'DisplayName',sprintf('AAE (%d/%d nm)', ...
            wl_small(1), wl_small(2)));

    plot(time, AAE_large, ...
        'b','LineWidth',1.5, ...
        'DisplayName',sprintf('AAE (%d/%d nm)', ...
            wl_large(1), wl_large(2)));

    grid on
    box on
    set(gca,'FontSize',15,'LineWidth',1.2)

    xlim([datetime(time_range(1)), datetime(time_range(2))])

    ylabel('Ångström Exponent (AAE)')
    xlabel('Time')

    legend('Location','best','FontSize',13)

    % ============================
    % Histogram
    % ============================
    ax_hist = axes('Position', ...
        [left_margin + ts_width + horizontal_gap, ...
         bottom_margin, ...
         hist_width, ...
         height]);
    hold on

    histogram(AAE_fit, ...
        'Normalization','pdf', ...
        'Orientation','horizontal', ...
        'FaceColor','k', ...
        'EdgeColor','none', ...
        'FaceAlpha',0.4);

    histogram(AAE_small, ...
        'Normalization','pdf', ...
        'Orientation','horizontal', ...
        'FaceColor','r', ...
        'EdgeColor','none', ...
        'FaceAlpha',0.4);

    histogram(AAE_large, ...
        'Normalization','pdf', ...
        'Orientation','horizontal', ...
        'FaceColor','b', ...
        'EdgeColor','none', ...
        'FaceAlpha',0.4);

    grid on
    box on
    set(gca,'FontSize',15,'LineWidth',1.2)

    xlabel('PDF')
    set(gca,'YTickLabel',[])

    linkaxes([ax_ts ax_hist],'y')

    sgtitle(sprintf('AAE (b_{abs} > %.2f Mm^{-1})', b_threshold), ...
        'FontSize',18, ...
        'FontWeight','normal')

end