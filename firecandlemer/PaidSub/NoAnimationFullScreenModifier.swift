import SwiftUI
import UIKit

struct NoAnimationFullScreenModifier<PresentedContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let presentedContent: () -> PresentedContent
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> PresentedContent) {
        self._isPresented = isPresented
        self.presentedContent = content
    }
    
    func body(content: Content) -> some View {
        content.background(
            NoAnimationFullScreenWrapper(
                isPresented: $isPresented,
                presentedContent: presentedContent()
            )
        )
    }
}

private struct NoAnimationFullScreenWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let presentedContent: Content
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.isOpaque = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let isCurrentlyPresented = uiViewController.presentedViewController != nil
        
        switch (isCurrentlyPresented, isPresented) {
        case (false, true):
            let hostingController = UIHostingController(rootView: presentedContent)
            hostingController.view.backgroundColor = .clear
            hostingController.modalPresentationStyle = .overFullScreen
            hostingController.view.isOpaque = false
            hostingController.modalTransitionStyle = .crossDissolve
            
            // Configure transparency
            if let window = uiViewController.view.window {
                window.backgroundColor = .clear
            }
            uiViewController.view.superview?.backgroundColor = .clear
            
            context.coordinator.setupPresentationController(hostingController.presentationController)
            uiViewController.present(hostingController, animated: false)
            
        case (true, false):
            // Immediately hide view before dismissing
            uiViewController.presentedViewController?.view.isHidden = true
            uiViewController.dismiss(animated: false) { 
                self.isPresented = false
            }
            
        default: break
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var parent: NoAnimationFullScreenWrapper
        
        init(_ parent: NoAnimationFullScreenWrapper) {
            self.parent = parent
        }
        
        func setupPresentationController(_ presentationController: UIPresentationController?) {
            presentationController?.delegate = self
            presentationController?.presentedView?.backgroundColor = .clear
            presentationController?.containerView?.backgroundColor = .clear
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.isPresented = false
        }
    }
}

extension View {
    func noAnimationFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(NoAnimationFullScreenModifier(isPresented: isPresented, content: content))
    }
} 