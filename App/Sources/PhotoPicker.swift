import PhotosUI
import SwiftUI

#if os(iOS)
import UIKit
#endif

/// The photo row used by a bag and by a purchase: what there is now, and the
/// two ways to change it. Big targets, no menus.
struct PhotoRow: View {
    let title: String
    let hint: String
    @Binding var photoID: String?
    let identifier: String

    @EnvironmentObject private var store: CoffeeStore
    @State private var picked: PhotosPickerItem?
    @State private var showCamera = false
    @State private var viewing = false

    private var data: Data? {
        guard let photoID else { return nil }
        return store.photo(photoID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))

            if photoID != nil {
                Button { viewing = true } label: {
                    PhotoImage(data: data)
                        .frame(height: 190)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(identifier)-view")
            } else {
                PhotoImage(data: nil)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottom) {
                        Text(hint)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 12)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("\(identifier)-empty")
            }

            FlowRow(spacing: 8) {
                #if os(iOS)
                Button { showCamera = true } label: {
                    Text("📷  Take one")
                }
                .buttonStyle(SquashyButton(tint: Candy.bubblegum))
                .accessibilityIdentifier("\(identifier)-camera")
                #endif

                PhotosPicker(selection: $picked, matching: .images) {
                    Text("🖼  Choose one")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Candy.blueberry))
                }
                .accessibilityIdentifier("\(identifier)-choose")

                if photoID != nil {
                    Button { photoID = nil } label: {
                        Text("✕  Remove")
                    }
                    .buttonStyle(SquashyButton(tint: Candy.sky))
                    .accessibilityIdentifier("\(identifier)-remove")
                }
            }
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            Task {
                if let raw = try? await item.loadTransferable(type: Data.self) {
                    photoID = store.keepPhoto(raw)
                }
                picked = nil
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { raw in
                photoID = store.keepPhoto(raw)
            }
            .ignoresSafeArea()
        }
        #endif
        .sheet(isPresented: $viewing) {
            PhotoViewer(data: data)
        }
    }
}

/// Tap a photo and it fills the screen. Nothing else on it but a way out.
struct PhotoViewer: View {
    let data: Data?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let data, let image = PhotoImage.image(from: data) {
                image.resizable().scaledToFit().ignoresSafeArea()
            }
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        CrossMark(size: 22, weight: 5)
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(Circle().fill(.black.opacity(0.55)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("photo-viewer-close")
                    .padding(18)
                }
                Spacer()
            }
        }
    }
}

#if os(iOS)
/// The system camera. A bag photo is taken at the machine, not chosen from a
/// library, so this is the button that matters on the phone.
struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info:
                                   [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let raw = image.jpegData(compressionQuality: 0.95) {
                parent.onCapture(raw)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
