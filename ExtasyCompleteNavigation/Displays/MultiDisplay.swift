//
//  MultiDisplay.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 3.10.23.
//

import SwiftUI
import SwiftData

struct MultiDisplay: View {
    
    @Environment(NMEAReader.self) private var navigationReadings
    //initial states for the display segments before any data has been saved
    @State var identifier: [Int] = [0, 1, 2, 3]
    @Query var data: [Matrix]
    @Environment(\.modelContext) var context
    
    var body: some View {
        
        GeometryReader{ geometry in
            
            ZStack{
                
                //MARK: - Display Separators
                HorizontalLine()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .leading, endPoint: .trailing))
                
                VerticalLine()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("line_start"), Color("line_mid"), Color("line_end")]), startPoint: .center, endPoint: .bottom))
                
                
                VStack{
                    //MARK: - Big Display Cell
                    //identifier will be changed & saved in this view
                    
                    Menu(){
                        Menu("Wind") {
                            ForEach(displayCell){ cell in
                                if cell.tag == "wind" {
                                    Button(action: {
                                        identifier[0] = checkSlotMenu(a: cell.id, oldValue: identifier[0])
                                        
                                    }, label: {
                                        Text(cell.name)
                                    })
                                }
                            }
                        }
                        Menu("Speed"){
                            ForEach(displayCell){ cell in
                                if cell.tag == "speed" {
                                    Button(action: {
                                        identifier[0] = checkSlotMenu(a: cell.id, oldValue: identifier[0])
                                        
                                    }, label: {
                                        Text(cell.name)
                                    })
                                }
                            }
                        }
                        Menu("Others"){
                            ForEach(displayCell){ cell in
                                if cell.tag == "other" {
                                    Button(action: {
                                        identifier[0] = checkSlotMenu(a: cell.id, oldValue: identifier[0])
                                    }, label: {
                                        Text(cell.name)
                                    })
                                }
                            }
                        }
                    } label: {
                        //MARK: - The Whole Cell is a Big Button
                        BigDisplayCell(cell: displayCell[identifier[0]], valueID: identifier[0])
                    }//END OF LABEL
                    
                    HStack(alignment: .bottom, spacing: nil){
                        
                        //MARK: - Small Left Display Cell
                        Menu(){
                            Menu("Wind") {
                                ForEach(displayCell){ cell in
                                    if cell.tag == "wind" {
                                        Button(action: {
                                            identifier[1] = checkSlotMenu(a: cell.id, oldValue: identifier[1])
                                            
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                            Menu("Speed"){
                                ForEach(displayCell){ cell in
                                    if cell.tag == "speed" {
                                        Button(action: {
                                            identifier[1] = checkSlotMenu(a: cell.id, oldValue: identifier[1])
                                            
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                            Menu("Others"){
                                ForEach(displayCell){ cell in
                                    if cell.tag == "other" {
                                        Button(action: {
                                            identifier[1] = checkSlotMenu(a: cell.id, oldValue: identifier[1])
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                        } label: {
                            
                            SmallDisplayCell(cell: displayCell[identifier[1]],
                                             valueID: identifier[1])
                        }//END OF LABEL
                        
                        
                        
                        //MARK: - Small Middle Display Cell
                        
                        Menu(){
                            Menu("Wind") {
                                ForEach(displayCell){ cell in
                                    if cell.tag == "wind" {
                                        Button(action: {
                                            identifier[2] = checkSlotMenu(a: cell.id, oldValue: identifier[2])
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                            Menu("Speed"){
                                ForEach(displayCell){ cell in
                                    if cell.tag == "speed" {
                                        Button(action: {
                                            identifier[2] = checkSlotMenu(a: cell.id, oldValue: identifier[2])
                                            
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                            Menu("Others"){
                                ForEach(displayCell){ cell in
                                    if cell.tag == "other" {
                                        Button(action: {
                                            identifier[2] = checkSlotMenu(a: cell.id, oldValue: identifier[2])
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                        } label: {
                            
                            SmallDisplayCell(cell: displayCell[identifier[2]],
                                             valueID: identifier[2])
                        }//END OF LABEL
                        
                        //MARK: - Small Right Display Cell
                        
                        Menu(){
                            Menu("Wind") {
                                ForEach(displayCell){ cell in
                                    if cell.tag == "wind" {
                                        Button(action: {
                                            identifier[3] = checkSlotMenu(a: cell.id, oldValue: identifier[3])
                                            
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                            Menu("Speed"){
                                ForEach(displayCell){ cell in
                                    if cell.tag == "speed" {
                                        Button(action: {
                                            identifier[3] = checkSlotMenu(a: cell.id, oldValue: identifier[3])
                                            
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                            Menu("Others"){
                                ForEach(displayCell){ cell in
                                    if cell.tag == "other" {
                                        Button(action: {
                                            identifier[3] = checkSlotMenu(a: cell.id, oldValue: identifier[3])
                                        }, label: {
                                            Text(cell.name)
                                        })
                                    }
                                }
                            }
                        } label: {
                            
                            SmallDisplayCell(cell: displayCell[identifier[3]],
                                             valueID: identifier[3])
                        }//END OF LABEL
                    }//END OF HSTACK
                }//END OF VSTACK
            }//END OF ZSTACK
            .ignoresSafeArea()
            //MARK: - Save / Load Data Config in the Display
            .onAppear(){
                if data.isEmpty {
                    let model = Matrix(identifier: identifier)
                    context.insert(model)
                } else {
                    identifier = data.last!.identifier
                }
            }
            .onChange(of: identifier) { oldValue, newValue in
                let model = Matrix(identifier: newValue)
                print(newValue)
                context.insert(model)
                print(data.count)
            }
        }//END OF GEOMETRY
        .aspectRatio(contentMode: .fit)
    }//END OF BODY
    
    
    //MARK: - Check for Duplicate Values in the Other Cells
    func checkSlotMenu(a: Int, oldValue: Int) -> Int {
        
        //check if the slot is already taken
        let check = identifier.contains(a)
        //print(check)
        //check which one is the correct position
        if check == true {
            for index in 0..<identifier.count {
                //once found exchange the displays
                if a == identifier[index] {
                    identifier[index] = oldValue
                    return a
                }
            }
            //if the slot is not taken, just return the value
        } else {
            return a
        }
        
        return -1
    }
}//END OF STRUCTURE

#Preview {
    
    MultiDisplay()
        .environment(NMEAReader())
        .modelContainer(for: [Matrix.self, UserSettingsMenu.self])
    
}

