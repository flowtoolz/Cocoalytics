import SwiftUI

public struct DoubleSidebarView<LeftSidebar: View, Content: View, RightSidebar: View>: View
{
    init(viewModel: DoubleSidebarViewModel,
         content: @escaping () -> Content,
         leftSidebar: @escaping () -> LeftSidebar,
         rightSidebar: @escaping () -> RightSidebar)
    {
        self.viewModel = viewModel
        self.content = content
        self.leftSidebar = leftSidebar
        self.rightSidebar = rightSidebar
    }
    
    public var body: some View
    {
        NavigationSplitView(columnVisibility: $columnVisibility)
        {
            leftSidebar()
                .navigationSplitViewColumnWidth(min: Self.minimumWidth,
                                                ideal: 300,
                                                max: 600)
                .listStyle(.sidebar)
                .focused($focus, equals: .leftSidebar)
                .focusable(false)
                
        }
        detail:
        {
            ZStack
            {
                GeometryReader
                {
                    geo in
                    
                    HStack(spacing: 0)
                    {
                        Spacer()
                        
                        rightSidebar()
                            .frame(width: max(Self.minimumWidth, rightCurrentWidth - rightDragOffset))
                            .frame(maxHeight: .infinity)
                            .focused($focus, equals: .rightSidebar)
                            .focusable(false)
                    }
                    
                    HStack(spacing: 0)
                    {
                        content()
                            .frame(width: (geo.size.width - (rightCurrentWidth - rightDragOffset)) - 1)
                            .frame(maxHeight: .infinity)
                            .background(Color(NSColor.windowBackgroundColor))
                            .focused($focus, equals: .content)
                            .focusable(false)
                        
                        Rectangle()
                            .fill(colorScheme == .dark ? .black : Color(white: 0.8706))
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                        
                        Spacer()
                    }

                    DragHandle()
                        .position(x: (geo.size.width - (rightCurrentWidth - rightDragOffset)) - 0.5,
                                  y: geo.size.height / 2)
                        .gesture(
                            DragGesture()
                                .onChanged
                                {
                                    if !isDragging
                                    {
                                        isDragging = true
                                        NSCursor.resizeLeftRight.push()
                                    }
                                    
                                    let widthWithoutDrag = viewModel.showsRightSidebar ? rightWidthWhenVisible : 0
                                    
                                    let potentialRightPosition = (geo.size.width - widthWithoutDrag) + $0.translation.width

                                    guard potentialRightPosition >= minimumContentWidth else { return }

                                    rightDragOffset = $0.translation.width
                                }
                                .onEnded { _ in endDraggingRight() }
                        )
                }
            }
        }
        .onChange(of: viewModel.showsLeftSidebar)
        {
            showsLeftSidebar in
            
            withAnimation
            {
                columnVisibility = showsLeftSidebar ? .doubleColumn : .detailOnly
            }
        }
        .onAppear
        {
            focus = .leftSidebar
        }
        .onChange(of: focus)
        {
            [focus] newFocus in

            let contentOrRightLostFocus = newFocus == nil && focus != .leftSidebar
            if contentOrRightLostFocus { self.focus = .leftSidebar }
        }
    }
    
    // MARK: - Focus
    
    @FocusState private var focus: Focus?
    private enum Focus: String, Hashable { case leftSidebar, content, rightSidebar }
    
    // MARK: - Content
    
    @ViewBuilder public let content: () -> Content
    private let minimumContentWidth = 200.0
    
    // MARK: - Left Sidebar

    @ViewBuilder public let leftSidebar: () -> LeftSidebar
    
    @State var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    
    // MARK: - Right Sidebar
    
    @ViewBuilder public let rightSidebar: () -> RightSidebar
    
    @State private var isDragging = false
        
    private func endDraggingRight()
    {
        NSCursor.pop()
        isDragging = false
        
        let draggedWidth = rightCurrentWidth - rightDragOffset
        
        let expanded = draggedWidth >= Self.minimumWidth
        
        if expanded
        {
            rightWidthWhenVisible = draggedWidth
            rightDragOffset = 0
            viewModel.showsRightSidebar = true
        }
        else
        {
            withAnimation
            {
                rightDragOffset = 0
                viewModel.showsRightSidebar = false
            }
        }
    }

    var rightCurrentWidth: Double
    {
        viewModel.showsRightSidebar ? rightWidthWhenVisible : 0
    }
    
    @SceneStorage("rightWidthWhenVisible") var rightWidthWhenVisible = defaultWidth
    
    @State var rightDragOffset: Double = 0
    static var defaultWidth: Double { 250 }
    static var minimumWidth: Double { 200 }
    
    // MARK: - General
    
    @ObservedObject var viewModel: DoubleSidebarViewModel
    @Environment(\.colorScheme) var colorScheme
}

class DoubleSidebarViewModel: ObservableObject
{
    @Published var showsLeftSidebar: Bool = true
    @AppStorage("Show Right Sidebar") var showsRightSidebar: Bool = false
}

struct DragHandle: View
{
    var body: some View
    {
        Rectangle()
            .fill(.clear)
            .frame(maxHeight: .infinity)
            .frame(width: 10)
            .onHover
            {
                if $0 { NSCursor.resizeLeftRight.push() }
                else { NSCursor.pop() }
            }
    }
}
