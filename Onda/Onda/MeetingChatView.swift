//
//  MeetingChatView.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import PhotosUI
import SwiftUI
import UIKit

struct MeetingChatView: View {
    let meeting: MeetingSession

    @State private var messages = ChatMessage.sampleMessages
    @State private var draft = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingInfo = false
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        privacyNote

                        messageHistory
                            .padding(.top, 28)

                        reaction
                            .padding(.top, 30)

                        Color.clear
                            .frame(height: 1)
                            .id(ChatAnchor.bottom)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(ChatAnchor.bottom, anchor: .bottom)
                    }
                }
                .onChange(of: isComposerFocused) { _, isFocused in
                    guard isFocused else { return }
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(ChatAnchor.bottom, anchor: .bottom)
                    }
                }
            }

            composer
                .padding(.horizontal, 16)
                .padding(.bottom, isComposerFocused ? 8 : 32)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Meeting chat")
                        .font(.headline)
                        .foregroundStyle(Palette.ink)

                    Text("\(meeting.peopleSummary) · Encrypted")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                .accessibilityElement(children: .combine)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingInfo = true
                } label: {
                    Image(systemName: "info")
                        .font(.body.weight(.bold))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Palette.brandSoft)
                .foregroundStyle(Palette.brand)
                .accessibilityLabel("Meeting chat information")
            }
        }
        .tint(Palette.brand)
        .preferredColorScheme(.light)
        .alert("Meeting chat", isPresented: $isShowingInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Messages are encrypted and disappear when the meeting ends.")
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                await attachPhoto(item)
            }
        }
    }

    private var privacyNote: some View {
        Text("Messages disappear when the meeting ends")
            .font(.caption)
            .foregroundStyle(Palette.secondaryText)
            .frame(maxWidth: 330, minHeight: 48)
            .background(Palette.chatPrivacyNote)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Privacy notice: Messages disappear when the meeting ends")
    }

    private var messageHistory: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                ChatMessageRow(message: message)
                    .padding(.top, message.author != nil && index > 0 ? 10 : 0)
            }
        }
    }

    private var reaction: some View {
        HStack(spacing: 6) {
            Text("Martina reacted")

            Image(systemName: "heart.fill")
                .font(.caption2)
        }
        .font(.caption)
        .foregroundStyle(Palette.secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Martina reacted with a heart")
    }

    private var composer: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "plus")
                    .font(.title3.weight(.regular))
                    .foregroundStyle(Palette.brand)
                    .frame(width: 26, height: 44)
            }
            .accessibilityLabel("Attach a photo")

            TextField("Message everyone", text: $draft)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .focused($isComposerFocused)
                .submitLabel(.send)
                .onSubmit(sendMessage)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.body.weight(.bold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .tint(Palette.brand)
            .foregroundStyle(.white)
            .accessibilityLabel("Send message")
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .frame(height: 62)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(Palette.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }

    private func sendMessage() {
        let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDraft.isEmpty else { return }

        withAnimation {
            messages.append(ChatMessage(text: trimmedDraft, isMine: true))
        }
        draft = ""
    }

    private func attachPhoto(_ item: PhotosPickerItem) async {
        defer { selectedPhoto = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              UIImage(data: data) != nil else { return }

        withAnimation {
            messages.append(ChatMessage(imageData: data, isMine: true))
        }
    }
}

private struct ChatMessageRow: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: message.isMine ? .trailing : .leading, spacing: 6) {
            if let author = message.author {
                Text(author)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .padding(.leading, 4)
            }

            messageBubble
        }
        .frame(maxWidth: .infinity, alignment: message.isMine ? .trailing : .leading)
    }

    @ViewBuilder
    private var messageBubble: some View {
        if let imageData = message.imageData,
           let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 164)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityLabel(message.isMine ? "Photo sent by you" : "Photo from \(message.author ?? "participant")")
        } else if let text = message.text {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(message.isMine ? Color.white : Palette.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 58)
                .background(message.isMine ? Palette.brand : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: 300, alignment: message.isMine ? .trailing : .leading)
                .accessibilityLabel("\(message.isMine ? "You" : message.author ?? "Participant"): \(text)")
        }
    }
}

private struct ChatMessage: Identifiable {
    let id = UUID()
    let author: String?
    let text: String?
    let imageData: Data?
    let isMine: Bool

    init(author: String? = nil, text: String, isMine: Bool) {
        self.author = author
        self.text = text
        imageData = nil
        self.isMine = isMine
    }

    init(imageData: Data, isMine: Bool) {
        author = nil
        text = nil
        self.imageData = imageData
        self.isMine = isMine
    }

    static let sampleMessages = [
        ChatMessage(author: "Martina", text: "Can everyone see my screen?", isMine: false),
        ChatMessage(text: "Yes — all clear on my side.", isMine: true),
        ChatMessage(author: "Paolo", text: "The prototype feels much faster now.", isMine: false),
        ChatMessage(text: "Great. I’ll share the notes after this.", isMine: true)
    ]
}

private enum ChatAnchor {
    static let bottom = "chat-bottom"
}

extension Palette {
    static let chatPrivacyNote = Color(red: 237 / 255, green: 240 / 255, blue: 247 / 255)
}

#Preview {
    NavigationStack {
        MeetingChatView(meeting: .designSync)
    }
}
