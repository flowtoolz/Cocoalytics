import SwiftUI

struct CodebaseAnalysisContentPanel: View
{
    var body: some View
    {
        VStack(spacing: 0)
        {
            PathBarView(overviewBar: processorVM.pathBar)
            
            SearchBarView(processorVM: processorVM,
                          artifactName: artifactName)
            
            Divider()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ObservedObject var processorVM: CodebaseProcessorViewModel
    
    let artifactName: String
}
