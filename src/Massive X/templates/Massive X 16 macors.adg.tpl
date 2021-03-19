<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="5" MinorVersion="11.0_433" Creator="Ableton Live 11.0" Revision="9dc150af94686f816d2cf27815fcf2907d4b86f8">
	<GroupDevicePreset>
		<OverwriteProtectionNumber Value="2816" />
		<Device>
			<InstrumentGroupDevice Id="0">
				<LomId Value="0" />
				<LomIdView Value="0" />
				<IsExpanded Value="true" />
				<On>
					<LomId Value="0" />
					<Manual Value="true" />
					<AutomationTarget Id="0">
						<LockEnvelope Value="0" />
					</AutomationTarget>
					<MidiCCOnOffThresholds>
						<Min Value="64" />
						<Max Value="127" />
					</MidiCCOnOffThresholds>
				</On>
				<ModulationSourceCount Value="0" />
				<ParametersListWrapper LomId="0" />
				<Pointee Id="0" />
				<LastSelectedTimeableIndex Value="0" />
				<LastSelectedClipEnvelopeIndex Value="0" />
				<LastPresetRef>
					<Value>
						<AbletonDefaultPresetRef Id="0">
							<FileRef>
								<RelativePathType Value="5" />
								<RelativePath Value="Racks/Instrument Racks/Instrument Rack" />
								<Path Value="/Applications/Ableton Live 11 Suite.app/Contents/App-Resources/Core Library/Racks/Instrument Racks/Instrument Rack" />
								<Type Value="2" />
								<LivePackName Value="Core Library" />
								<LivePackId Value="www.ableton.com/0" />
								<OriginalFileSize Value="0" />
								<OriginalCrc Value="0" />
							</FileRef>
							<DeviceId Name="InstrumentGroupDevice" />
						</AbletonDefaultPresetRef>
					</Value>
				</LastPresetRef>
				<LockedScripts />
				<IsFolded Value="false" />
				<ShouldShowPresetName Value="true" />
				<UserName Value="" />
				<Annotation Value="" />
				<SourceContext>
					<Value />
				</SourceContext>
				<OverwriteProtectionNumber Value="2816" />
				<Branches />
				<IsBranchesListVisible Value="false" />
				<IsReturnBranchesListVisible Value="false" />
				<IsRangesEditorVisible Value="false" />
				<AreDevicesVisible Value="true" />
				<NumVisibleMacroControls Value="<%= macros.length > 16 ? 16 : macros.length %>" /><% _.forEach(macros.slice(0, 16), function(macro, index) { %>
				<MacroControls.<%=index%>>
					<LomId Value="0" />
					<Manual Value="<%=127 * macro.normalizedValue%>" />
					<MidiControllerRange>
						<Min Value="0" />
						<Max Value="127" />
					</MidiControllerRange>
					<AutomationTarget Id="0">
						<LockEnvelope Value="0" />
					</AutomationTarget>
					<ModulationTarget Id="0">
						<LockEnvelope Value="0" />
					</ModulationTarget>
				</MacroControls.<%=index%>><% }); _.forEach(macros.slice(0, 16), function(macro, index) { %>
				<MacroDisplayNames.<%=index%> Value="<%=macro.name%>" /><% }); %>
				<MacroDefaults.0 Value="-1" />
				<MacroDefaults.1 Value="-1" />
				<MacroDefaults.2 Value="-1" />
				<MacroDefaults.3 Value="-1" />
				<MacroDefaults.4 Value="-1" />
				<MacroDefaults.5 Value="-1" />
				<MacroDefaults.6 Value="-1" />
				<MacroDefaults.7 Value="-1" />
				<MacroDefaults.8 Value="-1" />
				<MacroDefaults.9 Value="-1" />
				<MacroDefaults.10 Value="-1" />
				<MacroDefaults.11 Value="-1" />
				<MacroDefaults.12 Value="-1" />
				<MacroDefaults.13 Value="-1" />
				<MacroDefaults.14 Value="-1" />
				<MacroDefaults.15 Value="-1" />
				<MacroAnnotations.0 Value="" />
				<MacroAnnotations.1 Value="" />
				<MacroAnnotations.2 Value="" />
				<MacroAnnotations.3 Value="" />
				<MacroAnnotations.4 Value="" />
				<MacroAnnotations.5 Value="" />
				<MacroAnnotations.6 Value="" />
				<MacroAnnotations.7 Value="" />
				<MacroAnnotations.8 Value="" />
				<MacroAnnotations.9 Value="" />
				<MacroAnnotations.10 Value="" />
				<MacroAnnotations.11 Value="" />
				<MacroAnnotations.12 Value="" />
				<MacroAnnotations.13 Value="" />
				<MacroAnnotations.14 Value="" />
				<MacroAnnotations.15 Value="" />
				<ForceDisplayGenericValue.0 Value="false" />
				<ForceDisplayGenericValue.1 Value="false" />
				<ForceDisplayGenericValue.2 Value="false" />
				<ForceDisplayGenericValue.3 Value="false" />
				<ForceDisplayGenericValue.4 Value="false" />
				<ForceDisplayGenericValue.5 Value="false" />
				<ForceDisplayGenericValue.6 Value="false" />
				<ForceDisplayGenericValue.7 Value="false" />
				<ForceDisplayGenericValue.8 Value="false" />
				<ForceDisplayGenericValue.9 Value="false" />
				<ForceDisplayGenericValue.10 Value="false" />
				<ForceDisplayGenericValue.11 Value="false" />
				<ForceDisplayGenericValue.12 Value="false" />
				<ForceDisplayGenericValue.13 Value="false" />
				<ForceDisplayGenericValue.14 Value="false" />
				<ForceDisplayGenericValue.15 Value="false" />
				<AreMacroControlsVisible Value="true" />
				<IsAutoSelectEnabled Value="false" />
				<ChainSelector>
					<LomId Value="0" />
					<Manual Value="0" />
					<MidiControllerRange>
						<Min Value="0" />
						<Max Value="127" />
					</MidiControllerRange>
					<AutomationTarget Id="0">
						<LockEnvelope Value="0" />
					</AutomationTarget>
					<ModulationTarget Id="0">
						<LockEnvelope Value="0" />
					</ModulationTarget>
				</ChainSelector>
				<ChainSelectorRelativePosition Value="-1073741824" />
				<ViewsToRestoreWhenUnfolding Value="0" />
				<ReturnBranches />
				<BranchesSplitterProportion Value="0.5" />
				<ShowBranchesInSessionMixer Value="false" />
				<MacroColor.0 Value="-1" />
				<MacroColor.1 Value="-1" />
				<MacroColor.2 Value="-1" />
				<MacroColor.3 Value="-1" />
				<MacroColor.4 Value="-1" />
				<MacroColor.5 Value="-1" />
				<MacroColor.6 Value="-1" />
				<MacroColor.7 Value="-1" />
				<MacroColor.8 Value="-1" />
				<MacroColor.9 Value="-1" />
				<MacroColor.10 Value="-1" />
				<MacroColor.11 Value="-1" />
				<MacroColor.12 Value="-1" />
				<MacroColor.13 Value="-1" />
				<MacroColor.14 Value="-1" />
				<MacroColor.15 Value="-1" />
				<LockId Value="0" />
				<LockSeal Value="0" />
				<ChainsListWrapper LomId="0" />
				<ReturnChainsListWrapper LomId="0" />
				<MacroVariations>
					<MacroSnapshots />
				</MacroVariations>
				<ExcludeMacroFromRandomization.0 Value="false" />
				<ExcludeMacroFromRandomization.1 Value="false" />
				<ExcludeMacroFromRandomization.2 Value="false" />
				<ExcludeMacroFromRandomization.3 Value="false" />
				<ExcludeMacroFromRandomization.4 Value="false" />
				<ExcludeMacroFromRandomization.5 Value="false" />
				<ExcludeMacroFromRandomization.6 Value="false" />
				<ExcludeMacroFromRandomization.7 Value="false" />
				<ExcludeMacroFromRandomization.8 Value="false" />
				<ExcludeMacroFromRandomization.9 Value="false" />
				<ExcludeMacroFromRandomization.10 Value="false" />
				<ExcludeMacroFromRandomization.11 Value="false" />
				<ExcludeMacroFromRandomization.12 Value="false" />
				<ExcludeMacroFromRandomization.13 Value="false" />
				<ExcludeMacroFromRandomization.14 Value="false" />
				<ExcludeMacroFromRandomization.15 Value="false" />
				<ExcludeMacroFromSnapshots.0 Value="false" />
				<ExcludeMacroFromSnapshots.1 Value="false" />
				<ExcludeMacroFromSnapshots.2 Value="false" />
				<ExcludeMacroFromSnapshots.3 Value="false" />
				<ExcludeMacroFromSnapshots.4 Value="false" />
				<ExcludeMacroFromSnapshots.5 Value="false" />
				<ExcludeMacroFromSnapshots.6 Value="false" />
				<ExcludeMacroFromSnapshots.7 Value="false" />
				<ExcludeMacroFromSnapshots.8 Value="false" />
				<ExcludeMacroFromSnapshots.9 Value="false" />
				<ExcludeMacroFromSnapshots.10 Value="false" />
				<ExcludeMacroFromSnapshots.11 Value="false" />
				<ExcludeMacroFromSnapshots.12 Value="false" />
				<ExcludeMacroFromSnapshots.13 Value="false" />
				<ExcludeMacroFromSnapshots.14 Value="false" />
				<ExcludeMacroFromSnapshots.15 Value="false" />
				<AreMacroVariationsControlsVisible Value="false" />
				<ChainSelectorFilterMidiCtrl Value="false" />
				<RangeTypeIndex Value="1" />
				<ShowsZonesInsteadOfNoteNames Value="false" />
			</InstrumentGroupDevice>
		</Device>
		<PresetRef>
			<AbletonDefaultPresetRef Id="0">
				<FileRef>
					<RelativePathType Value="5" />
					<RelativePath Value="Racks/Instrument Racks/Instrument Rack" />
					<Path Value="/Applications/Ableton Live 11 Suite.app/Contents/App-Resources/Core Library/Racks/Instrument Racks/Instrument Rack" />
					<Type Value="2" />
					<LivePackName Value="Core Library" />
					<LivePackId Value="www.ableton.com/0" />
					<OriginalFileSize Value="0" />
					<OriginalCrc Value="0" />
				</FileRef>
				<DeviceId Name="InstrumentGroupDevice" />
			</AbletonDefaultPresetRef>
		</PresetRef>
		<BranchPresets>
			<InstrumentBranchPreset Id="0">
				<Name Value="" />
				<IsSoloed Value="false" />
				<DevicePresets>
					<VstPreset Id="0">
						<OverwriteProtectionNumber Value="2816" />
						<ParameterSettings>
							<PluginParameterSettings Id="0">
								<Index Value="0" />
								<VisualIndex Value="0" />
								<ParameterId Value="0" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="0" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="1">
								<Index Value="1" />
								<VisualIndex Value="1" />
								<ParameterId Value="1" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="1" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="2">
								<Index Value="2" />
								<VisualIndex Value="2" />
								<ParameterId Value="2" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="2" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="3">
								<Index Value="3" />
								<VisualIndex Value="3" />
								<ParameterId Value="3" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="3" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="4">
								<Index Value="4" />
								<VisualIndex Value="4" />
								<ParameterId Value="4" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="4" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="5">
								<Index Value="5" />
								<VisualIndex Value="5" />
								<ParameterId Value="5" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="5" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="6">
								<Index Value="6" />
								<VisualIndex Value="6" />
								<ParameterId Value="6" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="6" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="7">
								<Index Value="7" />
								<VisualIndex Value="7" />
								<ParameterId Value="7" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="7" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="8">
								<Index Value="8" />
								<VisualIndex Value="8" />
								<ParameterId Value="8" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="8" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="9">
								<Index Value="9" />
								<VisualIndex Value="9" />
								<ParameterId Value="9" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="9" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="10">
								<Index Value="10" />
								<VisualIndex Value="10" />
								<ParameterId Value="10" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="10" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="11">
								<Index Value="11" />
								<VisualIndex Value="11" />
								<ParameterId Value="11" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="11" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="12">
								<Index Value="12" />
								<VisualIndex Value="12" />
								<ParameterId Value="12" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="12" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="13">
								<Index Value="13" />
								<VisualIndex Value="13" />
								<ParameterId Value="13" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="13" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="14">
								<Index Value="14" />
								<VisualIndex Value="14" />
								<ParameterId Value="14" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="14" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
							<PluginParameterSettings Id="15">
								<Index Value="15" />
								<VisualIndex Value="15" />
								<ParameterId Value="15" />
								<Type Value="PluginFloatParameter" />
								<MacroControlIndex Value="15" />
								<MidiControllerRange>
									<MidiControllerRange Id="0">
										<Min Value="0" />
										<Max Value="1" />
									</MidiControllerRange>
								</MidiControllerRange>
								<LomId Value="0" />
							</PluginParameterSettings>
						</ParameterSettings>
						<IsOn Value="true" />
						<PowerMacroControlIndex Value="-1" />
						<PowerMacroMappingRange>
							<Min Value="64" />
							<Max Value="127" />
						</PowerMacroMappingRange>
						<IsFolded Value="false" />
						<StoredAllParameters Value="true" />
						<DeviceLomId Value="0" />
						<DeviceViewLomId Value="0" />
						<IsOnLomId Value="0" />
						<ParametersListWrapperLomId Value="0" />
						<Type Value="1178747752" />
						<ProgramCount Value="1" />
						<ParameterCount Value="16" />
						<ProgramNumber Value="0" />
						<Buffer><% _.forEach(bufferLines, function(line) { %>
							<%=line%><% }); %>
						</Buffer>
						<Name Value="" />
						<PluginVersion Value="1" />
						<UniqueId Value="1315513416" />
						<ByteOrder Value="2" />
						<PresetRef />
					</VstPreset>
				</DevicePresets>
				<MixerPreset>
					<AbletonDevicePreset Id="0">
						<OverwriteProtectionNumber Value="2816" />
						<Device>
							<AudioBranchMixerDevice Id="0">
								<LomId Value="0" />
								<LomIdView Value="0" />
								<IsExpanded Value="true" />
								<On>
									<LomId Value="0" />
									<Manual Value="true" />
									<AutomationTarget Id="0">
										<LockEnvelope Value="0" />
									</AutomationTarget>
									<MidiCCOnOffThresholds>
										<Min Value="64" />
										<Max Value="127" />
									</MidiCCOnOffThresholds>
								</On>
								<ModulationSourceCount Value="0" />
								<ParametersListWrapper LomId="0" />
								<Pointee Id="0" />
								<LastSelectedTimeableIndex Value="0" />
								<LastSelectedClipEnvelopeIndex Value="0" />
								<LastPresetRef>
									<Value />
								</LastPresetRef>
								<LockedScripts />
								<IsFolded Value="false" />
								<ShouldShowPresetName Value="true" />
								<UserName Value="" />
								<Annotation Value="" />
								<SourceContext>
									<Value />
								</SourceContext>
								<OverwriteProtectionNumber Value="2816" />
								<Speaker>
									<LomId Value="0" />
									<Manual Value="true" />
									<AutomationTarget Id="0">
										<LockEnvelope Value="0" />
									</AutomationTarget>
									<MidiCCOnOffThresholds>
										<Min Value="64" />
										<Max Value="127" />
									</MidiCCOnOffThresholds>
								</Speaker>
								<Volume>
									<LomId Value="0" />
									<Manual Value="1" />
									<MidiControllerRange>
										<Min Value="0.0003162277571" />
										<Max Value="1.99526238" />
									</MidiControllerRange>
									<AutomationTarget Id="0">
										<LockEnvelope Value="0" />
									</AutomationTarget>
									<ModulationTarget Id="0">
										<LockEnvelope Value="0" />
									</ModulationTarget>
								</Volume>
								<Panorama>
									<LomId Value="0" />
									<Manual Value="0" />
									<MidiControllerRange>
										<Min Value="-1" />
										<Max Value="1" />
									</MidiControllerRange>
									<AutomationTarget Id="0">
										<LockEnvelope Value="0" />
									</AutomationTarget>
									<ModulationTarget Id="0">
										<LockEnvelope Value="0" />
									</ModulationTarget>
								</Panorama>
								<SendInfos />
								<RoutingHelper>
									<Routable>
										<Target Value="AudioOut/None" />
										<UpperDisplayString Value="No Output" />
										<LowerDisplayString Value="" />
									</Routable>
									<TargetEnum Value="0" />
								</RoutingHelper>
								<SendsListWrapper LomId="0" />
							</AudioBranchMixerDevice>
						</Device>
						<PresetRef>
							<AbletonDefaultPresetRef Id="0">
								<FileRef>
									<RelativePathType Value="0" />
									<RelativePath Value="" />
									<Path Value="" />
									<Type Value="2" />
									<LivePackName Value="" />
									<LivePackId Value="" />
									<OriginalFileSize Value="0" />
									<OriginalCrc Value="0" />
								</FileRef>
								<DeviceId Name="AudioBranchMixerDevice" />
							</AbletonDefaultPresetRef>
						</PresetRef>
					</AbletonDevicePreset>
				</MixerPreset>
				<BranchSelectorRange>
					<Min Value="0" />
					<Max Value="0" />
					<CrossfadeMin Value="0" />
					<CrossfadeMax Value="0" />
				</BranchSelectorRange>
				<SessionViewBranchWidth Value="55" />
				<DocumentColorIndex Value="3" />
				<AutoColored Value="true" />
				<AutoColorScheme Value="0" />
				<SourceContext>
					<BranchSourceContext Id="0">
						<OriginalFileRef />
						<BrowserContentPath Value="" />
						<PresetRef />
						<BranchDeviceId Value="device:vst:instr:1315513416?n=Massive%20X" />
					</BranchSourceContext>
				</SourceContext>
				<ZoneSettings>
					<KeyRange>
						<Min Value="0" />
						<Max Value="127" />
						<CrossfadeMin Value="0" />
						<CrossfadeMax Value="127" />
					</KeyRange>
					<VelocityRange>
						<Min Value="1" />
						<Max Value="127" />
						<CrossfadeMin Value="1" />
						<CrossfadeMax Value="127" />
					</VelocityRange>
				</ZoneSettings>
			</InstrumentBranchPreset>
		</BranchPresets>
		<ReturnBranchPresets />
	</GroupDevicePreset>
</Ableton>
