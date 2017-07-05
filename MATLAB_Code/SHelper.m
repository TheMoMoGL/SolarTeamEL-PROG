classdef SHelper
    %SHELPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [B] = DecimalHourToHourFomrat(dNumber,timeInfo)
    % Convert 2.88 hours to hh:mm:ss
    % 2.88 hours can be broken down to 2 hours plus 0.88 hours - 2 hours
    % 0.88 hours * 60 minutes/hour = 52.8 minutes - 52 minutes
    % 0.8 minutes * 60 seconds/minute = 48 seconds - 48 seconds
    % 02:52:48
    [hour,minute] = deal(fix(dNumber), dNumber-fix(dNumber));
    minute = minute * 60;
    [minute,second] = deal(fix(minute), minute-fix(minute));
    second = second * 60;
    [second,value] = deal(fix(second), minute-fix(second));
    t = datetime;
    t.Year = timeInfo.Year;
    t.Month = timeInfo.Month;
    t.Day = timeInfo.Day;
    t.Hour = hour;
    t.Minute = minute;
    t.Second = second;
    t.TimeZone = timeInfo.TimeZone;
    B = t;
        end

        function [B] = DecimalMinuteToHourFormat(dNumber,timeInfo)
    % Convert 78.6 minutes to hh:mm:ss
    % 78.6 minutes can be converted to hours by dividing 78.6 minutes / 60 minutes/hour = 1.31 hours
    % 1.31 hours can be broken down to 1 hour plus 0.31 hours - 1 hour
    % 0.31 hours * 60 minutes/hour = 18.6 minutes - 18 minutes
    % 0.6 minutes * 60 seconds/minute = 36 seconds - 36 seconds
    % 01:18:36
    if dNumber > 60
         dNumber = dNumber/60;
        [hour,minute] = deal(fix(dNumber), dNumber-fix(dNumber));
        minute = minute * 60;
        [minute,second] = deal(fix(minute), minute-fix(minute));
        second = second * 60;
        [second,value] = deal(fix(second), minute-fix(second));
        t = datetime;
        t.Year = timeInfo.Year;
        t.Month = timeInfo.Month;
        t.Day = timeInfo.Day;
        t.Hour = hour;
        t.Minute = minute;
        t.Second = second;
        t.TimeZone = timeInfo.TimeZone;
        B = t;
    else
        dNumber = dNumber /100;
        [hour,minute] = deal(fix(dNumber), dNumber-fix(dNumber));
        minute = minute * 60;
        [minute,second] = deal(fix(minute), minute-fix(minute));
        second = second * 60;
        [second,value] = deal(fix(second), minute-fix(second));
        t = datetime;
        t.Hour = hour;
        t.Minute = minute;
        t.Second = second;
        t.TimeZone = timeZone;
        B = t;
    end
   
end

        function [B] = CalculateDayOfYear(dTime)
            B = day(dTime,'dayofyear');
        end

        function [EoT] = CalculateEoT(dTime)
            % Equation Of Time (EOT)
            % the time difference between apparent solar time and mean solar time;
            % https://www.hindawi.com/journals/isrn/2011/217484/
            % there are few methods to do this, it seems to be most accurate one
            d = CalculateDayOfYear(dTime);

            N = (2*pi*(d-1)/365);
            EoT = 229.18*(0.000075+0.001868*cos(N)...
                - 0.032077*sin(N)-0.014615*cos(2*N)...
                - 0.04089*sin(2*N));
        end

        function [TC] = CalculateTC(LSTM,longitude,EoT)
            % Time Correction Factor (TC)
            TC = 4 * (LSTM - longitude) + EoT;
        end

        function [LST] = CalculateLST(localTime,TC)
            % Local Solar Time (LST)
            if(isdst(localTime))
                localTime.Hour = localTime.Hour - 1;
            end

            LST = localTime + minutes(TC);
        end

        function [LSTM] = CalculateLSTM(longitude)
            %Local Standard Time Meridian (LSTM)
            LSTM = double( 15 * uint32(longitude/15));
        end

        function [SolarConstant,SolarConstantCorrected,SolarConstantCorrectedAndScaled] = CalculateSolarFluxConstants(scalingFactor,dTime)
            % Solar Constant
            % E = 1367 W/m2 Paper can be found in the description
            % http://www.itacanet.org/the-sun-as-a-source-of-energy/part-4-irradiation-calculations/
            % insolation intensity on a plane perpendicular to sun rays

            N = CalculateDayOfYear(dTime);
            SolarConstant = 1367;
            correctingFactor = 1 + 0.034 * cos(2*pi*(N/365.25));
            SolarConstantCorrected = SolarConstant * correctingFactor;
            SolarConstantCorrectedAndScaled = SolarConstantCorrected * scalingFactor;
        end

        function [insolationIntensity] = CalculateInsolationIntensity(solarConstant,zenithAngle)
            % Calculate the insolation on a plane horizontal to the Earth’s surface
            % at the site’s latitude. this consider zenith Angle so it means it
            % considers the angel of sun's ray towards surface of panels
            % radiation input for 1 sq.m area expressed in Joules/sec = W/m2
            radFactor = pi/180;
            insolationIntensity = solarConstant * cos(zenithAngle * radFactor);
            if (insolationIntensity < 0)
                insolationIntensity = 0;
            end
        end

        function [insolationIntensity] = CalculateInsolationIntensityBetweenTwoHours(solarConstant,latitude,declinationAngle,hourAngel1,hourAngel2)
    % Calculate the insolation between 2 hours, assumes perpendicular ray
    % towards surface of panels, this method can be used when we are
    % stopping the car so we can tilt the panels towards sun
    % radiation input for 1 sq.m area expressed in Joules/sec = W/m2
    radFactor = pi/180;
    P1 = ((12 * 3600)/pi)*solarConstant;
    P2 = cos(latitude*radFactor)*cos(declinationAngle*radFactor);
    P3 = sin(hourAngel2 * radFactor)-sin(hourAngel1 * radFactor);
    P4 = radFactor * (hourAngel2-hourAngel1);
    P5 = sin(latitude*radFactor)*sin(declinationAngle*radFactor);
    
    P6 = P3 + (P4 * P5);
    insolationIntensity = P1 * (P2 * P6); % W/m2
end

        function [DA] = CalculateDeclinationAngle(dTime)
            N = CalculateDayOfYear(dTime);
            % same for entire globe excep few exceptions
            % usually relies between -23.45 to +23.45
            % http://www.reuk.co.uk/wordpress/solar/solar-declination/

            radFactor = pi/180;
            P1 = ((360/365.24)*(N-2))*radFactor;
            P2 = sin(P1);
            P3 = (360/pi)*0.0167;
            P4 = P2 * P3;
            P5 = (360/365.24)*(N+10);
            P6 = cos((P4 + P5)*radFactor);
            P7 = sin(-23.44*radFactor)*P6;
            P8 = asin(P7);

            DA =radtodeg(P8);

        end

        function [HA] = CalculateHourAngle(LST)
            % Positive for afternoons, negetive for mornings
            % There is another argument which uses the opposit signs
            hour = LST.Hour;
            minute = LST.Minute;
            totalMinutesPassMidnight = (hour * 60) + minute;
            HA = (totalMinutesPassMidnight-720)/4;
        end

        function [altitudeAngle] = CalculateSolarAltitudeAngle(latitude,declinationAngle,hourAngle)
            radFactor = pi/180;
            degFactor = 180/pi;
            P1 = cos(latitude * radFactor) * cos(declinationAngle * radFactor) * cos(hourAngle * radFactor);
            P2 = sin(latitude * radFactor) * sin(declinationAngle * radFactor);
            altitudeAngle = degFactor * asin(P1 + P2);
        end

        function [zenithAngle] = CalculateZenithAngle(latitude,declinationAngle,hourAngle)
            radFactor = pi/180;
            degFactor = 180/pi;
            altitudeAngle = CalculateSolarAltitudeAngle(latitude,declinationAngle,hourAngle);
            zenithAngle = degFactor * acos(altitudeAngle * radFactor);
        end

        function [azimuthAngle] = CalculateAzimuthAngle(latitude, declinationAngle,altitudeAngle)
            % The solar azimuth, ?1, is the angle away from south (north in the Southern Hemisphere). 
            radFactor = pi/180;
            degFactor = 180/pi;

            P1 = sin(altitudeAngle * radFactor) * sin(latitude * radFactor) - sin(declinationAngle * radFactor);
            P2 = cos(altitudeAngle * radFactor) * cos(latitude * radFactor);

            azimuthAngle = degFactor * acos( P1 / P2);
        end

        function [sunRiseHourAngle,noonAltitude,sunSetHourAngle,sunRiseTimeStandard,sunSetTimeStandard] = CalculateDayAngles(latitude,declinationAngle,timeInfo,longitude,EoT,UTCoffset)
    % The sun rises and sets when its altitude is 0°, not
    % necessarily when its hour angle is ±90°
    % where HS is negative for sunrise and positive for sunset.
    % https://se.mathworks.com/matlabcentral/fileexchange/55509-sunrise-sunset/content/SunriseSunset.mlx
    radFactor = pi/180;
    degFactor = 180/pi;
    noonAltitude = 90 - latitude + declinationAngle;
    
    P = -tan(latitude * radFactor) * tan(declinationAngle * radFactor);
    sunSetHourAngle = degFactor * acos(P);
    sunRiseHourAngle = sunSetHourAngle * -1;
    
    longCorr = CalculateLongitudeCorrection(longitude,UTCoffset);
    solarCorr = CalculateSolarCorrection(longCorr,EoT);
    
    % calculate sunRise time
    sr = 12 - acosd(-tand(latitude)*tand(declinationAngle))/15 - solarCorr/60;
    sunRiseTimeStandard = DecimalHourToHourFomrat(sr,timeInfo);
    
    % calculate sunSet time
    st  = 12 + acosd(-tand(latitude)*tand(declinationAngle))/15 - solarCorr/60;
    sunSetTimeStandard = DecimalHourToHourFomrat(st,timeInfo);
end

        function [angleOfIncidence] = CalculateAngleOfIncidence(latitude,declinationAngle,hourAngle)
    % Assuming the surface is flat (i.e. horizontal) ?=0, cos ? = 1, sin ? = 0
    % should be equal to Zenith angle
    % note if you tilt the surface this formala does not apply
    radFactor = pi/180;
    degFactor = 180/pi;
    P1 = cos(declinationAngle * radFactor) * cos(latitude * radFactor) * cos(hourAngle * radFactor);
    P2 = sin(declinationAngle * radFactor) * sin(latitude * radFactor);
    angleOfIncidence = degFactor * acos(P1+P2);
    
end

        function [collectedSolarPower] = CalculateCollectedSolarPower(insolationIntensity,solarPanelEf,solarPanelArea, scalingFactor)
    % READ CAREFULLY ATTENTION
    % There are 2 options to call this method:
    % 1: To calculate collected soalr power while car is moving:
    % insolationIntensity should be calcualted using
    % CalculateInsolationIntensity method
    % --------------------------------------------------------------------
    % 2: To calculate collected soalr power while car stop:
    % insolationIntensity should be calcualted using
    % CalculateInsolationIntensityBetweenTwoHours 
    % possible stops during day:
    % stop 1 = sunrise till 8:00 AM
    % stop 2 = 12:00 to 12:30 PM
    % stop 3 = 5:00 till sunset
    % --------------------------------------------------------------------
    % radiation input for 1 sq.m area expressed in Joules/sec = W/m2
    
    collectedSolarPower = insolationIntensity * solarPanelEf * solarPanelArea * scalingFactor;
        end

        function [longitudeCorrection] = CalculateLongitudeCorrection(longitude,UTCoffset)
   longitudeCorrection = 4*(longitude - 15*UTCoffset) ;  
end

        function [solarCorrection] = CalculateSolarCorrection(longitudeCorrection,EoT)
   solarCorrection = longitudeCorrection + EoT;
end

        function [avbSolarPower,collectedSolarPower] = CalculateSolarPowerInstantaneously(time, longitude,latitude,solarPanelArea,solarPanelEf,scalingFactor,solarFluxScalingFactor)
    EoT = CalculateEoT(time);
    LSTM = CalculateLSTM(longitude);
    TC = CalculateTC(LSTM,longitude,EoT);
    LST= CalculateLST(time,TC);
    DA = CalculateDeclinationAngle(time);
    HA = CalculateHourAngle(LST);
    zenithAngle = CalculateZenithAngle(latitude,DA,HA);
    [~,~,SolarConstantCorrectedAndScaled] = CalculateSolarFluxConstants(solarFluxScalingFactor,time);
    avbSolarPower = CalculateInsolationIntensity(SolarConstantCorrectedAndScaled,zenithAngle);
    collectedSolarPower = CalculateCollectedSolarPower(avbSolarPower,solarPanelEf,solarPanelArea,scalingFactor);
    end

        function [avbSolarPower,collectedSolarPower] = CalculateInSolarPowerBetweenTwoHours(startTime,endTime, longitude,latitude,solarPanelArea,solarPanelEf,scalingFactor,solarFluxScalingFactor)
    % start time
    [dt,~] = tzoffset(startTime);
    UTCoffset = hours(dt);
    EoT = CalculateEoT(startTime);
    LSTM = CalculateLSTM(longitude);
    TC = CalculateTC(LSTM,longitude,EoT);
    LST= CalculateLST(startTime,TC);
    DA = CalculateDeclinationAngle(startTime);
    HA = CalculateHourAngle(LST);
    
     % end time
    EoT2 = CalculateEoT(endTime);
    LSTM2 = CalculateLSTM(longitude);
    TC2 = CalculateTC(LSTM2,longitude,EoT2);
    LST2= CalculateLST(endTime,TC2);
    DA2 = CalculateDeclinationAngle(endTime);
    HA2 = CalculateHourAngle(LST2);
    
    [sunRiseHourAngle,noonAltitude,sunSetHourAngle,sunRiseTimeStandard,sunSetTimeStandard] = CalculateDayAngles(latitude,DA,startTime,longitude,EoT,UTCoffset);
    
    % todo: if you want charging time before sunrise till 8 or after 5 till
    % sunset use the CalculateDayAngles angle's for HA and HA2
    
    [~,~,SolarConstantCorrectedAndScaled] = CalculateSolarFluxConstants(solarFluxScalingFactor,startTime);
    avbSolarPower = CalculateInsolationIntensityBetweenTwoHours(SolarConstantCorrectedAndScaled,latitude,DA,HA,HA2);
    collectedSolarPower = CalculateCollectedSolarPower(avbSolarPower,solarPanelEf,solarPanelArea,scalingFactor);
end
    end
    
end

