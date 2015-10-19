function obj = rgcCompute(obj, outerSegment, varargin)
% rgcCompute: a method of @rgc that computes the spiking output of the
% rgc mosaic to an arbitrary stimulus.
% 
% The responses for each mosaic are computed one at a time. For a given
% mosaic, first the spatial convolution of the center and surround RFs are
% calculated for each RGB channel, followed by the temporal responses for
% the center and surround and each RGB channel. This results in the linear
% response.
% 
% Next, the linear response is put through the generator function. The
% nonlinear response is the input to a function that computes spikes with
% Poisson statistics. For the rgcGLM object, the spikes are computed using
% the recursive influence of the post-spike and coupling filters between
% the nonlinear responses of other cells. These computations are carried
% out using code from Pillow, Shlens, Paninski, Sher, Litke, Chichilnisky,
% Simoncelli, Nature, 2008, licensed for modification, which can be found
% at 
% 
% http://pillowlab.princeton.edu/code_GLM.html
% 
% Outline:
% 1. Normalize stimulus
% 2. Compute linear response
%       - spatial convolution
%       - temporal convolution
% 3. Compute nonlinear response
% 4. Compute spiking response
% 
% Inputs: outersegment.
% 
% Outputs: the rgc object with responses.
% 
% Example:
% rgc1 = rgcCompute(rgc1, identityOS);
% 
% (c) isetbio
% 09/2015 JRG

%% 

for cellTypeInd = 1:length(obj.mosaic)
    
    nCells = size(obj.mosaic{cellTypeInd}.cellLocation);
    
    % Normalize stimulus
    
    spConvolveStimulus = osGet(outerSegment, 'coneCurrentSignal');
    spConvolveStimulus = spConvolveStimulus - mean(spConvolveStimulus(:));
    spConvolveStimulus = 10*spConvolveStimulus./max(spConvolveStimulus(:));
    
    % Given separable STRF, convolve 2D spatial RF then 1D temporal response.
     
    spResponse = spConvolve(obj.mosaic{cellTypeInd,1}, spConvolveStimulus);
    
    [fullResponse, nlResponse] = fullConvolve(obj.mosaic{cellTypeInd,1}, spResponse);
    
    obj.mosaic{cellTypeInd} = mosaicSet(obj.mosaic{cellTypeInd},'linearResponse', fullResponse);
%         
%     spikeResponse = computeSpikesGLM(obj.mosaic{cellTypeInd,1});
    
%     %%%%%%%%%%%%%%%
%     if isa(outerSegment,'osIdentity')
%         spConvolveStimulus = osGet(outerSegment, 'rgbData');
%         spConvolveStimulus = spConvolveStimulus;% - 0.5;%mean(spConvolveStimulus(:));
%         spConvolveStimulus = 1*spConvolveStimulus./max(abs(spConvolveStimulus(:)));
%     else
%         spConvolveStimulus = osGet(outerSegment, 'coneCurrentSignal');
%         spConvolveStimulus = spConvolveStimulus - mean(spConvolveStimulus(:));
%         spConvolveStimulus = 10*spConvolveStimulus./max(spConvolveStimulus(:));
%     end   
%     
%     % Given separable STRF, convolve 2D spatial RF then 1D temporal response.
%      
%     spResponse = spConvolve(obj.mosaic{cellTypeInd,1}, spConvolveStimulus);
%        
%     if isa(outerSegment,'osIdentity');    
%         [fullResponse, nlResponse] = fullConvolve(obj.mosaic{cellTypeInd,1}, spResponse);        
%     else        
%         
%         for xcell = 1:nCells(1)
%             for ycell = 1:nCells(2)
%                 fullResponse{xcell,ycell} = squeeze(mean(mean((spResponse{xcell,ycell,1}) - (spResponse{xcell,ycell,2}),1),2))';
%                 if ~isa(obj, 'rgcLinear')
%                     
%                     genFunc = obj.mosaic{cellTypeInd}.generatorFunction;
%                     nlResponse{xcell,ycell} = genFunc(fullResponse{xcell,ycell});
%                 end
%             end
%         end
%     end
%         
%     
%     obj.mosaic{cellTypeInd} = mosaicSet(obj.mosaic{cellTypeInd},'linearResponse', fullResponse);
%     
%     if ~isa(obj, 'rgcLinear')
%         
%         obj.mosaic{cellTypeInd} = mosaicSet(obj.mosaic{cellTypeInd},'nlResponse', nlResponse);
%         
%         %%% Compute spikes
%         
%         % for cellTypeInd = 1%:4%obj.numberCellTypes
%         %     obj.mosaic{cellTypeInd,1}.spikeResponse = computeSpikes(obj.mosaic{cellTypeInd,1}.nlResponse, sensor, outersegment);
%         fprintf('Spike generation, %s:      \n', obj.mosaic{cellTypeInd}.cellType);
%         tic
%         
%         if isa(obj,'rgcLNP');
%             spikeResponse = computeSpikes(obj.mosaic{cellTypeInd,1}.nlResponse, 0);
%             % elseif 0
%             %     spikeResponse = computeSpikesPSF(obj.mosaic{cellTypeInd,1}.nlResponse, obj.mosaic{cellTypeInd}.postSpikeFilter, sensor, outersegment);
%         elseif isa(obj,'rgcGLM')|isa(obj,'rgcSubunit')
%             spikeResponse = computeSpikesGLM(obj.mosaic{cellTypeInd,1});
%         end
%         % obj = rgcMosaicSet(obj, 'spikeResponse', spikeResponse);
%         
%         obj.mosaic{cellTypeInd} = mosaicSet(obj.mosaic{cellTypeInd},'spikeResponse', spikeResponse);
%         
%         [raster psth] = computePSTH(obj.mosaic{cellTypeInd,1});
%         
%         obj.mosaic{cellTypeInd} = mosaicSet(obj.mosaic{cellTypeInd},'rasterResponse',raster);
%         obj.mosaic{cellTypeInd} = mosaicSet(obj.mosaic{cellTypeInd},'psthResponse',psth);
%         
%         toc
%         
%     end
    clear spResponse fullResponse nlResponse spikeResponse raster psth
end
close;
