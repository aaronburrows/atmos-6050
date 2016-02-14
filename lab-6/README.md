## Lab 6 - Plotting weather station data

### Introduction
**Objective** - Learn how to pre-process data and create simple data visualizations of common atmospheric variables using data collected from your recent weather station deployment.  You may use whatever plotting language you choose as long as all the required graphs are produced and look professional.  Part of this assignment is learning to properly comment your code.  You may *not* use MS Excel or any other spreadsheet program to complete this assignment.  You will be required to submit your computer code used to generate the graphics _and_ the data file you used.  Instructions for this will be at the end of this tutorial.

**Overview of the assignment**
  1. Pre-process raw data file
  2. Parse file and re-format
    - READ data file into Matlab (or other plotting language)
    - Convert raw data file into a `.MAT` or NetCDF file.
  3. Create meaningful graphs
    - READ post-processed data file into plotting language
    - Run data retrievals
    - Plot the data

You should read the short summary of [General Code Practices](general-code-practices.md) before you go much further.  Your code will not only be graded on its ability to function properly, but also whether it is easy to read and follows general conventions.

### Pre-process raw data file
Ideally in the real world you would want to automate this process by creating a computer script to do this work for you as often during a field campaign you collect more data than you know what to do with.  Also by automating this process you reduce the human errors such as mis-treating the data ("treating" meaning preparing the data).  You will see in the "Cupsonde" lab, we have provided you with a Perl script to automate the pre-processing of the data.  For this lab you can do this quickly for your single data file using any text editor of your choice.  Below is an example of how to do this using a regular text editor and _Vi_.

Using a standard text editor simple do the following:
  - Open your data file
  - Search and replace the following:
    - **"NAN"** with **-9999**
  - Save and close the file

With _Vi_ you can do the following from the command line
```BASH
vi CFEE2.dat
```

You will need to type `:` to tell _Vi_ to enter edit mode.  Now you should type the following at the prompt

```BASH
%s/"NAN"/-9999/
```

This will replace all the **"NAN"** with **-9999**. Then press `escape`. To exit and save your file in _Vi_, hold down the `shift` key type `zz`.

> Regardless if you used _Vi_ or not, please read http://www.linfo.org/vi/search.html and explain the syntax of the search command used above as part of your lab report.


### Read data into Matlab
Using the following code, read in your pre-processed data file and save file the file as a `MAT` file.  For other languages please store as a NetCDF/HDF file.  If you are truly brave and do this assignment in C/Fortran & GNUPLot, you can use whatever text file format you choose.

Before we get too far ahead of ourselves, let's think about the steps involved in the post processing phase of our code.

1. Read in file
2. Break the input string apart into new variables
3. Make any data corrections
4. Save new variables in output file
5. "Poke" or test the output file to ensure the data looks good.

Starting with reading in the file we will use `textscan()` because we have a date string for our timestamp.

```Matlab
fid = fopen(FI);
result = textscan(fid, FMT, 'delimiter',',');
fclose(fid);
```

where `FI` and `FMT` are defined as the input filename and read in format respectively.  Extracting the data from the return from `textscan()` is pretty simple.

```Matlab
data_variable = result{n};
```

Now we need to deal with the timestamp.  The CR1000 uses a string based timestamp which is difficult to use in computational sciences, so we will convert our string timestamp to POSIX time.  For brevity just accept that unix time starts at January 1, 1970, and Matlab time starts at January 1, 0000.  So here's how you make the conversion.

```Matlab
% Break apart the return array from textscan()
vector_time = result{1};
posix_time  = datenum(vector_time) - datenum('1970-01-01');
```

Saving your processed variables is pretty simple now.  Matlab takes the pain out of the process by giving you the `save()` command.  It's pretty simple to use; just tell it the file name followed by the variables you want to store.  We're adding the `v7.3` option just to be verbose about the file format.  After the file is saved, use the `whos()` function to poke the file to see what the dimensions are.

```Matlab
% Save in output file
save(FO, 'posix_time', 'vector_time', 'batt_voltage', 'air_tempc', ...
         'rel_hum', 'wind_spd', 'wind_max', 'wind_dir', 'pressure', ...
         '-v7.3')

% And verify the file
whos('-file', FO)
```

### Creating graphs

From this point forward we will work with our now processed data file.  The reason for all this previous work is to simplify sharing our data, as well as reducing data ingest errors when we analyze it.

For Matlab users, importing your dataset is pretty simple.  The following code will read in the dataset.

```Matlab
load(<filename>, '-mat');             % Read in data
```

Once this is done, you should see all your variables in the Matlab workspace.  If the file did not load correctly, double check the file path and name are correct.  If it did load, then we can start to work with our data.  Your first step should be to create a starting and finishing index to subset the data by the time period you want to investigate.

Consider the following segment of

```Matlab
date_start = '2016-02-02';          % Start & stop of time span
date_stop  = 'EOF';

posix_day1  = datenum('1970-01-01');
matlab_time = posix_time + posix_day1;

CDO = datenum(date_start);    % Campaign Day One in Matlab time

% Find start and end time indices
if ( strcmp(date_start, 'SOF') )
   A = posix_time(1) + posix_day1;
else
   A = datenum(date_start);
end
idx0 = min( find(matlab_time >= A) );

if ( strcmp(date_stop, 'EOF') )
   A = posix_time(end) + posix_day1;
else
   A = datenum(date_stop);
end
idx1 = min( find(matlab_time >= A) );

idx = idx0:idx1;

```

The quick summary of this is: we look for start and stop indices and then assign them as a single array called `idx`.

> For your lab report, please explain the algorithm here *or* come up with an alternate method to find the start and stop indices of your time array.

#### Retrievals

A retrieval in its simplest form is an algorithm in which you give it data, and retrieve a derived value.  Nearly every satellite product you use, and most forecasting tools are based on retrievals.  For this lab you will need to derive dew point temperature and daily minima/maxima values.  Finding the daily minima/maxima temperatures is not a retrieval by definition, but the process to find it computationally is very similar, so we will keep it in this section of code.  Don't worry, this is not a computer science class where you'll need to write your own sorting functions, but we will use classic methods and not Matlab's intrinsic tools.

First the dew point problem.  Using the following format for a function in Matlab, use the links in the comments to write the equation to calculate dew point from temperature and relative humidity (RH).

```Matlab
function [ Td ] = retDewPoint( temperature, rh )
%retDewPoint Returns dew point from temperature and rh
%

% http://www.srh.noaa.gov/images/epz/wxcalc/vaporPressure.pdf
% http://www.srh.noaa.gov/images/epz/wxcalc/wetBulbTdFromRh.pdf
% http://andrew.rsmas.miami.edu/bmcnoldy/humidity_conversions.pdf
%
% Alduchov, O. A., and R. E. Eskridge, 1996: Improved Magnus' form
%     approximation of saturation vapor pressure. J. Appl. Meteor.,
%     35, 601?609.
% August, E. F., 1828: Ueber die Berechnung der Expansivkraft des
%     Wasserdunstes. Ann. Phys. Chem., 13, 122?137.


   Td = ???

end
```

Here's how I called my dew point function

```Matlab
% Dew Point calculation, matches full index
dew_point = zeros(1, length(air_tempc));
for i = 1:length(air_tempc)
   dew_point(i) = retDewPoint(air_tempc(i), rel_hum(i));
end
```

Onward to finding the average daily temperature minimum and maximum.  Consider the following

```Matlab
% Find daily average high
a            = fix(min(matlab_time(idx)));
b            = fix(max(matlab_time(idx)));
granule_days = a:b;

daily_high = zeros(1, length(granule_days));
daily_low  = zeros(1, length(granule_days));

for i = 1:length(granule_days)

   A = min( find(matlab_time > granule_days(i)) );
   B = max( find(matlab_time < granule_days(i) + 1) );

   daily_high(i) = max(air_tempc(A:B));
   daily_low(i)  = min(air_tempc(A:B));

end
```

> For your lab report, please explain the algorithm here *or* come up with an alternate method to find the daily minimum and maximum.  

> Using your algorithm above, compute the average daily minimum and maximum.  You'll be plotting this later.

#### Making the graph

We have done quite a bit of work up to this point.  Now comes the fun part of creating the graphics that allow us to interpret the data.

Below is an example of my first plot.  Take some time to understand what is happening here.  This example covers nearly everything you need to know about basic XY plotting in Matlab.  Of course there are countless customization options and a few different ways to go about this, so don't be afraid to try new things rather than just copy-and-paste this code.

![temp-dewpoint][fig1]

> When writing your code, you should comment and explain what you are doing in your initial plot, then you can reduce your comments in subsequent images to things that aren't already explained.

```Matlab
% Figure 1
% Show temperature as a function of time. Display the average daily
% high, low and overall average

if (do_fig1 == 1)
   fprintf('Plotting figure 1 ...\n')
   f1 = figure(1);
   hold on;
   plot(matlab_time(idx), air_tempc(idx), '-k');
   plot(matlab_time(idx), dew_point(idx), '-.k');
   legend('Air Temp (C)', 'Dew Point (C)')
   %
   plot(get(gca,'xlim'), [mean_high, mean_high], '--r');
   plot(get(gca,'xlim'), [mean_low,  mean_low], ' --b');
   plot(get(gca,'xlim'), [0, 0],                 '--k');
   hold off;

   title('Temperature and Dew Point', 'FontSize', 14);
   xlabel('Time ', 'FontSize', 12);
   ylabel('Temperature (C)', 'FontSize', 12)
   box on;

   datetick('x', 'mmm-dd','keepticks')
   set(f1, 'Position', [100, 100, 850, 400]);
   set(gcf,'PaperUnits','inches', ...
           'PaperPosition',[0 0 8, 4.5], ...
           'PaperOrientation','landscape')
   print -f1 -dpng 'Temp-Dewpoint'

   clear f1
end
```

Creating sub plots takes just a few extra lines of code.  Consider the following when making your day-by-day plots like this

![day-by-day][fig2]

```Matlab
% Figure 2
% Show a contact sheet of each day's temperature and dew point
if (do_fig2 == 1)
    fprintf('Plotting figure 2 ...\n')

    % Determine the subplot matrix
    nx = ceil(length(granule_days) / 2);
    if (nx > 5)
        nx = 5;
    end
    ny = ceil(length(granule_days) / nx);

    f2 = figure(2);

    ymin = 5 * (floor( min(dew_point(idx)) / 5) );
    ymax = 5 * ( ceil( max(air_tempc(idx)) / 5) );

    for i = 1:length(granule_days)

        A = min( find(matlab_time > granule_days(i)) );
        B = max( find(matlab_time < granule_days(i) + 1) );

        subplot(ny, nx, i)
        hold on
        plot(matlab_time(A:B), air_tempc(A:B), '-k');
        plot(matlab_time(A:B), dew_point(A:B), '-.k');

        plot(get(gca,'xlim'), [daily_high(i), daily_high(i)], '--r');

            ... rest of plotting code goes here ...

        hold off

        set(gca,'xTick', ...
        (granule_days(i) + 0.00002):0.25:(granule_days(i) + 1.00001))

        if (i == 1)
            xlabel('Time (HH)', 'FontSize', 12)
            ylabel('Temp (C)', 'FontSize', 12)

            % Apply axis correction
            xlim([(granule_days(i) - 0.00001) (granule_days(i) + 1.00001)])
        end

        box on
        datetick('x', 'HH', 'keeplimits')
        title(datestr(granule_days(i)), 'FontSize', 12)
        ylim([ymin ymax])

    end

    set(f2, 'Position', [100, 100, nx * 300, ny * 250]);
    set(gcf,'PaperUnits','inches', ...
    'PaperPosition',[0 0 ...
                        round((nx * 300)/100), ...
                        round((ny * 250)/100)] )

    ... clean up code goes here ...

end
```

> Even if you don't use this code, explain what is happening here in your lab report.  Trivial as it may sound, the methods here will help you later on when you need to automate plotting, as well as it will help you write cleaner and more concise code.

## In closing

This lab covers a lot of information and a good programming skill set can take years to develop.  The best advice I can give is experiment with code, and look at other people's code both good and bad.  You'll know good code when you see it and bad when you see it.  Don't focus on using just one language either; if you understand *how* to solve the problem, then you'll be able to adapt to any other computer language quickly.


[fig1]: Temp-Dewpoint.png "Figure1"
[fig2]: day-by-day.png "Figure2"
