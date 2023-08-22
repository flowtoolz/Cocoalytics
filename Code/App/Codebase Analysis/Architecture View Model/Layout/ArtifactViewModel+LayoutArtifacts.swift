import FoundationToolz
import Foundation
import SwiftyToolz

extension ArtifactViewModel
{
    func layoutParts(forScopeSize scopeSize: Size,
                     ignoreSearchFilter: Bool)
    {
        let shownParts = ignoreSearchFilter ? parts : filteredParts
        
        if shownParts.isEmpty
        {
            showsParts = false
            return
        }
        
        gapBetweenParts = 2 * pow(scopeSize.surface, (1 / 6.0))
        
        showsParts = prepare(parts: shownParts,
                             forLayoutIn: Rectangle(size: scopeSize),
                             ignoreSearchFilter: ignoreSearchFilter)
        
        // TODO: this is correct but partly redundant. make sure we zero the layout of each hidden part only once.
        if !(showsParts ?? false)
        {
            layout(hiddenParts: parts, inScopeOfSize: scopeSize)
        }
    }
    
    @discardableResult
    private func prepare(parts: [ArtifactViewModel],
                         forLayoutIn availableRect: Rectangle,
                         ignoreSearchFilter: Bool) -> Bool
    {
        if parts.isEmpty { return false }
        
        // base case
        if parts.count == 1
        {
            let part = parts[0]
            
            part.frameInScopeContent = availableRect
            
            let padding = ArtifactViewModel.padding
            let headerHeight = part.fontSize + 2 * padding
            let contenFrameSize = Size(availableRect.width - (2 * padding),
                                       (availableRect.height - padding) - headerHeight)
            
            if contenFrameSize.width > ArtifactViewModel.minimumSize.width,
               contenFrameSize.height > ArtifactViewModel.minimumSize.height
            {
                part.contentFrame = Rectangle(position: Point(padding, headerHeight),
                                              size: contenFrameSize)
                
                part.layoutParts(forScopeSize: contenFrameSize,
                                 ignoreSearchFilter: ignoreSearchFilter)
            }
            else
            {
                part.showsParts = false
                
                if GlobalSettings.shared.useCorrectAnimations
                {
                    part.contentFrame = Rectangle(position: availableRect.size / 2)
                    
                    layout(hiddenParts: part.parts)
                }
            }
            
            return availableRect.width >= ArtifactViewModel.minimumSize.width &&
            availableRect.height >= ArtifactViewModel.minimumSize.height
        }
        
        // tree map algorithm
        let (partsA, partsB) = TreemapAlgorithm.split(parts)
        
        let lastComponentA = partsA.last?.metrics.componentRank
        let firstComponentB = partsB.first?.metrics.componentRank
        let isSplitBetweenComponents = lastComponentA == nil || firstComponentB == nil || lastComponentA != firstComponentB
        
        let locA = partsA.sum { $0.metrics.linesOfCode ?? 0 }
        let locB = partsB.sum { $0.metrics.linesOfCode ?? 0 }
        
        let fractionA = Double(locA) / Double(locA + locB)
        
        let regularGap = gapBetweenParts ?? 0
        let bigGap = 3 * regularGap
        
        if let rectSplit = TreemapAlgorithm.split(availableRect,
                                                  firstFraction: fractionA,
                                                  gap: isSplitBetweenComponents ? regularGap : bigGap,
                                                  minimumSize: ArtifactViewModel.minimumSize)
        {
            let partsACanBeShown = prepare(parts: partsA,
                                           forLayoutIn: rectSplit.0,
                                           ignoreSearchFilter: ignoreSearchFilter)
            
            if !partsACanBeShown && !GlobalSettings.shared.useCorrectAnimations { return false }
            
            let partsBCanBeShown = prepare(parts: partsB,
                                           forLayoutIn: rectSplit.1,
                                           ignoreSearchFilter: ignoreSearchFilter)
            
            return partsACanBeShown && partsBCanBeShown
        }
        else
        {
            if GlobalSettings.shared.useCorrectAnimations
            {
                layout(hiddenParts: parts,
                       inScopeOfSize: availableRect.size)
            }
            
            return false
        }
    }
    
    private func layout(hiddenParts parts: [ArtifactViewModel],
                        inScopeOfSize scopeSize: Size = .zero)
    {
        let center = Rectangle(position: scopeSize / 2)
        
        for part in parts
        {
            part.frameInScopeContent = center
            part.contentFrame = .zero
            
            layout(hiddenParts: part.parts)
        }
    }
}
