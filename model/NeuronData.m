classdef NeuronData < handle
    %   NeuronData is a class for representing the data structure for
    %   trial-based neural data.
    %   
    %   To construct an instance use "NeuronData(spikeTime, binSize)". See
    %   fit_armax_model.m for a demonstration of its use.
    %
    %   Copyright 2022 Ethan Trepka
    
   properties
      spikeTime
      
      binSize

      signalTime
      signalValue
      
      beginOfTrialSignal
      endOfTrialSignal
      
      alignTrialSignal
      maxTimeBeforeAlign
      maxTimeAfterAlign

      timeIntervalsAbsolute           % Absolute time values for each bin and trials         
      firingRateMat                   % Total firing rate for trial and bins
      firingRateMatMean
   end
   methods
        % Constructor
        function obj = NeuronData(spikeTime, binSize)
            % NeuronData constructs an instance of this class
            obj.spikeTime = spikeTime;
            obj.binSize = binSize;
        end
   end
        
   methods(Access = public)        
        function addSignalTime(obj, name, time)           
            obj.signalTime.(name) = time;
        end
        
        function addSignalValue(obj, name, value)
            obj.signalValue.(name) = value;
        end
        
        function addTrialBeginEndSignal(obj, beginOfTrialSignal, endOfTrialSignal)
            obj.beginOfTrialSignal = beginOfTrialSignal;
            obj.endOfTrialSignal = endOfTrialSignal;
        end
        
        function addAlignTrialSignal(obj, signalName, maxTimeBeforeAlign, maxTimeAfterAlign)
            obj.alignTrialSignal = signalName;
            obj.maxTimeBeforeAlign = maxTimeBeforeAlign;
            obj.maxTimeAfterAlign = maxTimeAfterAlign;
        end

        function binData(obj)            
            % Compute absolute time intervals for bins
            startPointEst = -obj.maxTimeBeforeAlign;
            endPointEst = obj.maxTimeAfterAlign;
            
            alignSignTime = obj.signalTime.(obj.alignTrialSignal);
            num_trials = size(alignSignTime,1);
            
            bin_range = [startPointEst:obj.binSize:endPointEst];
            num_bins = size(bin_range,2);

            obj.timeIntervalsAbsolute = repmat(bin_range,[num_trials,1]) + ...
                repmat(alignSignTime,[1, num_bins]);
            
            % Calculating Firing Rate Matrix
            obj.firingRateMat = [];
            
            trial_starts = obj.signalTime.(obj.beginOfTrialSignal);
            trial_ends = obj.signalTime.(obj.endOfTrialSignal);
                
            for cntTrial = 1:num_trials              
                % All spike in current trial
                allSpikes = obj.spikeTime;
                
                trialtimeIntervalsAbsolute = obj.timeIntervalsAbsolute(cntTrial,:);
                
                spikeCount = histc(allSpikes,trialtimeIntervalsAbsolute);
                spikeCount = spikeCount(1:end-1);
                
                if isempty(spikeCount)
                    spikeCount = zeros(length(trialtimeIntervalsAbsolute)-1,1);
                end
                
                if size(spikeCount,1)>1
                    spikeCount = spikeCount';
                end
                
                % make the spike count equal to nan, if the bin is
                % before cue_onT - 1 or after sample_onT + 2 because we
                % only want to fit in the interval 1 second before cue to
                % 2 seconds after sample

                trialtimeIntervalsAbsolute = trialtimeIntervalsAbsolute(1:end-1);
                spikeCount((trialtimeIntervalsAbsolute+obj.binSize) > obj.signalTime.sample(cntTrial) + 2000) = nan;
                spikeCount((trialtimeIntervalsAbsolute+obj.binSize) <  obj.signalTime.cue(cntTrial) - 1000) = nan;
                
                % convert spike count to firing rate and store in matrix
                obj.firingRateMat = [obj.firingRateMat; spikeCount/(obj.binSize/1000)];                
            end                     
           
            % calculate mean firing pattern in profile (psth)
            obj.firingRateMatMean = nanmean(obj.firingRateMat,1);
        end
    end
end