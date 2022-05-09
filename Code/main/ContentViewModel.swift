import SwiftUI
import SwiftObserver
import SwiftyToolz

class ContentViewModel: SwiftUI.ObservableObject, Observer
{
    init()
    {
        observe(Project.messenger)
        {
            switch $0
            {
            case .didCompleteAnalysis(let project):
                if project === Project.active,
                    let rootFolderArtifact = project.rootFolderArtifact {
                    self.artifacts = [rootFolderArtifact]
                }
            }
        }
    }
    
    @Published var artifacts = [CodeArtifact]()
    
    let receiver = Receiver()
}

func warningColor(for linesOfCode: Int) -> SwiftUI.Color
{
    if linesOfCode < 100 { return .green }
    else if linesOfCode < 200 { return .yellow }
    else if linesOfCode < 300 { return .orange }
    else { return .red }
}
