function ir = irComputeSpikes(ir, varargin)
% Generate spikes for certain rgc objects
%
% We have models that convert from the continuous response to the spiking
% output for several types of rgc mosaics.  This is the gateway routine
% that examines which rgc type we have and invokes the proper continuous to
% spike response for that type of rgc.
%
% Inputs: the inner retina object
%
% Outputs: the spikes responses are attached to the rgc mosaics in the ir
% object.
%
% Example:
%  os = osCreate('identity');
%  ir = irCreate(os,'model','glm');
%  ir.mosaicCreate('mosaicType','on midget');
%  ir.computeContinuous;
%  ir.computeSpike;
%
% JRG (c) isetbio

%% Required for Pillow code

% To be eliminated
global RefreshRate
RefreshRate = 100;    


%% Loop on the mosaics in the inner retina
for ii = 1:length(ir.mosaic)
    
    switch class(ir.mosaic{ii})
        case {'rgcGLM','rgcPhys'}
            % Call the Pillow code to generate spikes for the whole mosaic
            % using the coupled GLM
            clear responseSpikes responseVoltage
            % Modified
            % responseSpikes = computeSpikesGLM(ir.mosaic{ii,1});
            
            % Wrappers for adapting isetbio mosaic properties to Pillow code
            glminput = setGLMinput(ir.mosaic{ii}.responseLinear);
            glmprs   = setGLMprs(ir.mosaic{ii});
            % Run Pillow code
            [responseSpikesVec, Vmem] = simGLMcpl(glmprs, glminput');
            cellCtr = 0;
            nCells = size(ir.mosaic{ii}.responseLinear);
            responseSpikes = cell(nCells(2),nCells(1));
            responseVoltage = cell(nCells(2),nCells(1));
            for xc = 1:nCells(1)
                for yc = 1:nCells(2)
                    cellCtr = cellCtr+1;
                    responseSpikes{yc,xc} = responseSpikesVec{1,cellCtr};
                    responseVoltage{yc,xc} = Vmem(:,cellCtr);
                end
            end

            % Set mosaic property
            ir.mosaic{ii} = mosaicSet(ir.mosaic{ii},'responseSpikes', responseSpikes);
            ir.mosaic{ii} = mosaicSet(ir.mosaic{ii},'responseVoltage', responseVoltage);
        case {'rgcSubunit'}  
            % This is the computation based on Meister's paper:
            %
            % Eye Smarter than Scientists Believed: Neural Computations in Circuits of the Retina
            % Gollisch, Meister
            %  <http://www.sciencedirect.com/science/article/pii/S0896627309009994>
            % Meister lab:
            %  <https://sites.google.com/site/markusmeisterlab/home/research>
            % Baccus et al.
            %  A Retinal Circuit That Computes Object Motion
            %  <http://www.jneurosci.org/content/28/27/6807.full> 
            %
            % See also:
            % Pitkow and Meister
            % <https://drive.google.com/file/d/0B58h-HpFYJeKVlJUTllwZFBXWTA/edit>
            %
            % These subunit modules are little building blocks. We want to
            % separate ourselves from the complexity of the GLM model, but
            % reuse the appropriate to save coding time when possible.
            
            % Where we stand
            % Wrappers for adapting isetbio mosaic properties to Pillow code
            % Let's change the name of this function.
            % Maybe setMosaicInput
            
            % Reformat the linear response so we can invoke the Pillow
            % function simGLMcpl
            glminput = setGLMinput(ir.mosaic{ii}.responseLinear);
            
            % Set the post spike filter to enforce the refractory period.
            glmprs = setPSFprs(ir.mosaic{ii});
            
            % No post spike filter - break into different subclass?
            % glmprs = setLNPprs(ir.mosaic{ii});
            
            % Run Pillow code
            [responseSpikesVec, Vmem] = simGLMcpl(glmprs, glminput');
            cellCtr = 0;
            
            nCells = size(ir.mosaic{ii}.responseLinear);
            for xc = 1:nCells(1)
                for yc = 1:nCells(2)
                    cellCtr = cellCtr+1;
                    responseSpikes{yc,xc}  = responseSpikesVec{1,cellCtr};
                    responseVoltage{yc,xc} = Vmem(:,cellCtr);
                end
            end
            
            ir.mosaic{ii} = mosaicSet(ir.mosaic{ii},'responseSpikes', responseSpikes);            
            ir.mosaic{ii} = mosaicSet(ir.mosaic{ii},'responseVoltage', responseVoltage);
            
        case {'rgcLNP'}
            % This is a place holder for linear, nonlinear, poisson spiking
            % model.  The reference and computations will be explained
            % mainly here.
            glminput = setGLMinput(ir.mosaic{ii}.responseLinear);
            
            % Set the post spike filter to enforce the refractory period.
            glmprs = setPSFprs(ir.mosaic{ii});
            
            % No post spike filter - break into different subclass?
            % glmprs = setLNPprs(ir.mosaic{ii});
            
            % Run Pillow code
            [responseSpikesVec, Vmem] = simGLMcpl(glmprs, glminput');
            cellCtr = 0;
            
            nCells = size(ir.mosaic{ii}.responseLinear);
            for xc = 1:nCells(1)
                for yc = 1:nCells(2)
                    cellCtr = cellCtr+1;
                    responseSpikes{yc,xc} = responseSpikesVec{1,cellCtr};
                    responseVoltage{yc,xc} = Vmem(:,cellCtr);
                end
            end
            
            ir.mosaic{ii} = mosaicSet(ir.mosaic{ii},'responseSpikes', responseSpikes);
            ir.mosaic{ii} = mosaicSet(ir.mosaic{ii},'responseVoltage', responseVoltage);
        otherwise
            error('The rgcMosaic object is a model without a spike response; choose LNP or GLM for spikes.');
    end
end


end


